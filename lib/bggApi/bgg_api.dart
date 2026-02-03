import 'package:flutter_application_1/models/game_thing.dart';
import 'package:flutter_application_1/pages/log_page.dart';
import 'package:http/retry.dart';
import '../db/game_things_sql.dart';
import '../db/players_sql.dart';
import '../db/plays_sql.dart';
import '../db/location_sql.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/bgg_player_model.dart';
import '../models/bgg_play_model.dart';
import '../models/bgg_location.dart';
import 'dart:convert';
import 'package:requests/requests.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../task_checker.dart';
import '../login_handler.dart';
import '../globals.dart';
import 'dart:developer';
import '../s.dart';
import 'package:html/parser.dart' as parser;
import '../bggApi/xml_api_key.dart';

const maxPagesCount = 1000;
var bearerToken = api_key;

Future<void> importGameCollectionFromBGG(refreshProgress) async {
  await GameThingSQL.createTable();
  final collectionResponse = await http.get(
      Uri.parse(
          'https://boardgamegeek.com/xmlapi2/collection?username=${LoginHandler().login}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $bearerToken',
      });

  if (collectionResponse.statusCode == 200) {
    final rootNode = xml.XmlDocument.parse(collectionResponse.body);
    final itemsNode = rootNode.findElements('items').first;
    final items = itemsNode.findElements('item');
    var localGames = await GameThingSQL.getAllGames();
    List<int> bggGamesIds = [];
    for (final item in items) {
      final objectId = int.parse(item.getAttribute('objectid').toString());
      bggGamesIds.add(objectId);
      var existedGame = await GameThingSQL.selectGameByID(objectId);

      final objectName = item.findElements('name').first.innerText;
      final thumbnail = item.findElements('thumbnail').first.innerText;
      final image = item.findElements('image').first.innerText;
      final owned = int.parse(
          item.findElements('status').first.getAttribute('own').toString());
      var minPlayers = 0;
      var maxPlayers = 0;

      GameThing gameThing = GameThing(
          name: objectName,
          id: objectId,
          thumbnail: thumbnail,
          image: image,
          minPlayers: minPlayers,
          maxPlayers: maxPlayers,
          owned: owned);

      if (existedGame == null) {
        log("Importing game $objectName");
        refreshProgress(true, "Importing game $objectName");
        await GameThingSQL.addGame(gameThing);
      } else {
        if (!GameThing.areEquals(existedGame, gameThing)) {
          GameThingSQL.updateGame(gameThing);
        }
      }
    }
    // Deleting games that are not in BGG anymore.
    if (localGames != null) {
      var deletedGamesIds =
          localGames.where((e) => !bggGamesIds.contains(e.id)).toList();
      if (deletedGamesIds.isNotEmpty) {
        for (var deletedGameId in deletedGamesIds) {
          log("Deleting game ${deletedGameId.name}");
          GameThingSQL.deleteGame(deletedGameId);
        }
      }
    }
  }
}

Future<Map<String, dynamic>> getBggPlayerName(String username) async {
  final getPlayerResponse = await http.get(
      Uri.parse('https://boardgamegeek.com//xmlapi2/user?name=$username'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $bearerToken',
      });

  if (getPlayerResponse.statusCode == 200) {
    final rootNode = xml.XmlDocument.parse(getPlayerResponse.body);
    final userId = rootNode.rootElement.getAttribute('id');
    if (userId == null) return {};
    final userElement = rootNode.findAllElements('user').first;
    final firstNameElement = userElement.findElements('firstname').first;
    final firstName = firstNameElement.getAttribute('value');
    final lastnameElement = userElement.findElements('lastname').first;
    final lastname = lastnameElement.getAttribute('value');
    final name = lastname == null ? firstName : "$firstName $lastname";
    return {'id': int.parse(userId), 'preparedName': name};
  } else {
    return {};
  }
}

Future<void> getGamesThumbnail(refreshProgress, dynamic context) async {
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames != null) {
    int gamesWithThumbCount = gettingAllGames
        .where((e) => e.thumbBinary != null && e.thumbBinary!.isNotEmpty)
        .length;

    if (gamesWithThumbCount < gettingAllGames.length) {
      isLoadedAllGamesImagesNotifier.value = false;

      for (var game in gettingAllGames) {
        if (TaskChecker().needCancel) {
          return;
        }
        if (game.thumbBinary == null) {
          game.createBinaryThumb();
          refreshProgress(true,
              "${S.of(context).updatingThumbnails} $gamesWithThumbCount / ${gettingAllGames.length - 1}");
          gamesWithThumbCount += 1;
          // Anti DDOS
          await Future.delayed(Duration(milliseconds: loadTimeoutMs));
        }
      }
    }
    if (gamesWithThumbCount == gettingAllGames.length) {
      isLoadedAllGamesImagesNotifier.value = true;
      return;
    }
  }
}

Future<String> getGameThumbFromBGG(int gameId) async {
  var client = RetryClient(http.Client(), retries: 5);
  var gameThingResponse = await client.get(
      Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=$gameId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $bearerToken',
      });
  client.close();

  if (gameThingResponse.statusCode == 200) {
    final gameThingServer = GameThing.fromXml(gameThingResponse.body);
    return gameThingServer.thumbnail;
  } else {
    log("Error getting thumbnail for game ${gameId}");
    return "";
  }
}

Future<bool> checkAllGamesCountInfoLoaded() async {
  var isLoaded = false;
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames != null) {
    int gamesWithPlayerInfo = gettingAllGames
        .where((e) => e.minPlayers != 0 && e.maxPlayers != 0)
        .length;
    if (gamesWithPlayerInfo >= gettingAllGames.length) {
      isLoaded = true;
    } else {
      isLoaded = false;
    }
  }
  return isLoaded;
}

Future<bool> checkAllGamesImagesLoaded() async {
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames == null) {
    return true;
  }

  int gamesWithThumbCount = gettingAllGames
      .where((e) => e.thumbBinary != null && e.thumbBinary!.isNotEmpty)
      .length;

  if (gamesWithThumbCount == gettingAllGames.length) {
    return true;
  }

  return false;
}

Future<void> getGamesPlayersCount(refreshProgress, dynamic context) async {
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames != null) {
    int gamesWithPlayerInfo = gettingAllGames
        .where((e) => e.minPlayers != 0 && e.maxPlayers != 0)
        .length;
    if (gamesWithPlayerInfo < gettingAllGames.length) {
      isLoadedGamesPlayersCountInfoNotifier.value = false;
      for (var game in gettingAllGames) {
        if (TaskChecker().needCancel) {
          return;
        }
        if (game.minPlayers != 0 && game.maxPlayers != 0) continue;

        var client = RetryClient(http.Client(), retries: 5);
        var gameThingResponse = await client.get(
            Uri.parse(
                'https://boardgamegeek.com//xmlapi2/things?id=${game.id}'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $bearerToken',
            });
        client.close();

        if (gameThingResponse.statusCode == 200) {
          final gameThingServer = GameThing.fromXml(gameThingResponse.body);
          game.minPlayers = gameThingServer.minPlayers;
          game.maxPlayers = gameThingServer.maxPlayers;
          log("Update players count of game ${game.name} id = ${game.id}");
          refreshProgress(true,
              "${S.of(context).updatingGamePlayersInfo} $gamesWithPlayerInfo / ${gettingAllGames.length - 1}");
          gamesWithPlayerInfo += 1;
          await GameThingSQL.updateGame(game);
          // Anti DDOS
          await Future.delayed(Duration(milliseconds: loadTimeoutMs));
        } else {
          log("Error while getting info about game ${game.name} id = ${game.id}");
        }
      }
    }
    if (gamesWithPlayerInfo >= gettingAllGames.length) {
      isLoadedGamesPlayersCountInfoNotifier.value = true;
    }
  }
}

Future<void> getAllPlaysFromServer() async {
  for (var i = 1; i < maxPagesCount; i++) {
    int maxPlayerId = await PlayersSQL.getMaxID();
    int maxLocationId = await LocationSQL.getMaxID();
    var stillHavePlays = await getPlaysFromPage(i, maxPlayerId, maxLocationId);
    if (!stillHavePlays) break;
  }
}

Future<bool> getPlaysFromPage(
    int pageNumber, int maxPlayerId, maxLocationId) async {
  List<Player> uniquePlayers = [];
  List<Player> currentPlayers = [];
  List<String> winnersNames = [];
  List<Location> uniqueLocations = [];
  List<BggPlay> bggPlays = [];

  String sessionCookie = await _getSessionCookie();
  log("getPlaysFromPage. create players, iteration = $pageNumber");
  final collectionResponse = await http.get(
      Uri.parse(
          'https://boardgamegeek.com/xmlapi2/plays?username=${LoginHandler().login}&page=$pageNumber'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $bearerToken',
      });
  final rootNode = xml.XmlDocument.parse(collectionResponse.body);
  if (rootNode.findElements('plays').isEmpty) return false;
  final playsRoot = rootNode.findElements('plays').first;
  final plays = playsRoot.findElements('play');

  if (plays.isEmpty) return false;

  for (var play in plays) {
    winnersNames = [];
    final objectId = int.parse(play.getAttribute('id').toString());
    final date = play.getAttribute('date').toString();
    final location = play.getAttribute('location').toString();
    final duration = int.parse(play.getAttribute('length').toString());
    final quantity = int.parse(play.getAttribute('quantity').toString());
    final incomplete = int.parse(play.getAttribute('incomplete').toString());
    final comments = play.findElements('comments').firstOrNull != null
        ? play.findElements('comments').first.innerText
        : "";
    final gameId = int.parse(
        play.findElements('item').first.getAttribute('objectid').toString());
    final gameName =
        play.findElements('item').first.getAttribute('name').toString();

    if (location.isNotEmpty) {
      if (await LocationSQL.selectLocationByName(location) == null) {
        var gotLocation = Location(id: maxLocationId, name: location);
        if (!uniqueLocations.map((e) => e.name).contains(gotLocation.name)) {
          uniqueLocations.add(gotLocation);
        }
      }
    }

    final playersRoot = play.findElements('players').firstOrNull;
    if (playersRoot != null) {
      final players = playersRoot.findElements('player');
      currentPlayers.clear();
      // Structure of player:
      // (0) username="" | (1) userid="0" | (2) name="Саша" | (3) startposition=""
      //| (4) color="" | (5) score="42" | (6) new="0" | (7) rating="0" | (8) win="1"
      for (var player in players) {
        if (player.getAttribute('name') == null) continue;
        var newPlayer = Player(
          id: maxPlayerId,
          username: player.getAttribute('username').toString(),
          userid: int.parse(player.getAttribute('userid').toString()),
          name: player.getAttribute('name').toString(),
          startposition: player.getAttribute('startposition').toString(),
          color: player.getAttribute('color').toString(),
          score: player.getAttribute('score').toString(),
          isNew: player.getAttribute('new').toString(),
          rating: player.getAttribute('rating').toString(),
          win: player.getAttribute('win').toString(),
        );
        var win = player.getAttribute('win').toString();
        currentPlayers.add(newPlayer);

        if (win == '1') {
          winnersNames.add(newPlayer.name);
        }

        if (!uniquePlayers.map((e) => e.name).contains(newPlayer.name)) {
          if ((newPlayer.userid != 0 &&
                  await PlayersSQL.selectPlayerByUserID(newPlayer.userid!) ==
                      null) ||
              newPlayer.userid == 0) {
            if (await PlayersSQL.selectPlayerByName(newPlayer.name) == null) {
              uniquePlayers.add(newPlayer);
            }
          }
        }
      }
    }
    var bggPlay = BggPlay(
        id: objectId,
        gameId: gameId,
        gameName: gameName,
        date: date,
        comments: comments,
        duration: duration,
        quantity: quantity,
        incomplete: incomplete,
        location: location,
        players: currentPlayers
            .map((e) =>
                '${e.username.toString()}|${e.userid.toString()}|${e.name}|${e.startposition.toString()}|${e.color.toString()}|${e.score.toString()}|${e.isNew.toString()}|${e.rating.toString()}|${e.win.toString()}')
            .join(';'));
    var existedPlay = await PlaysSQL.selectPlayByID(bggPlay.id);
    if (existedPlay == null) {
      bggPlays.add(bggPlay);
    } else {
      if (!BggPlay.areEqual(existedPlay, bggPlay)) {
        existedPlay = bggPlay;
      }
    }
  }
  await fillLocalPlayers(uniquePlayers, maxPlayerId);
  await fillLocalLocations(uniqueLocations, maxLocationId);
  await fillLocalPlays(bggPlays);

  return true;
}

Future<void> fillLocalPlayers(
    List<Player> uniquePlayers, int maxPlayerId) async {
  var newBggPlayers = uniquePlayers.where((element) => element.userid != 0);
  for (var newPlayer in newBggPlayers) {
    if (await PlayersSQL.selectPlayerByUserID(newPlayer.userid!) != null) {
      log("Exist bgg player ${newPlayer.name}, userid = ${newPlayer.userid}");
    } else {
      log("creating bgg player ${newPlayer.name}");
      maxPlayerId++;
      newPlayer.id = maxPlayerId;
      PlayersSQL.addPlayer(newPlayer);
    }
  }
  var newNotBggPlayers = uniquePlayers.where((element) => element.userid == 0);

  for (var newPlayer in newNotBggPlayers) {
    var foundResult = await PlayersSQL.selectPlayerByName(newPlayer.name);
    if (foundResult != null) {
      log("Exist player name ${newPlayer.name}");
    } else {
      log("creating not bgg player ${newPlayer.name}");
      maxPlayerId++;
      newPlayer.id = maxPlayerId;
      PlayersSQL.addPlayer(newPlayer);
    }
  }
}

Future<void> fillLocalLocations(
    List<Location> newLocations, int maxLocationId) async {
  for (var newLocation in newLocations) {
    if (await LocationSQL.selectLocationByName(newLocation.name) != null) {
      log("Existed location: ${newLocation.name}");
    } else {
      log("New location :${newLocation.name}");
      maxLocationId++;
      newLocation.id = maxLocationId;
      newLocation.isDefault = 0;
      LocationSQL.addLocation(newLocation);
    }
  }
}

Future<void> fillLocalPlays(List<BggPlay> bggPlays) async {
  for (var bggPlay in bggPlays) {
    if (await PlaysSQL.selectPlayByID(bggPlay.id) != null) {
      log("Existed play: ${bggPlay.id}");
    } else {
      log("New play :${bggPlay.id}");
      PlaysSQL.addPlay(bggPlay);
    }
  }
}

Future<void> deleteObsoletePlays(List<BggPlay> bggPlays) async {
  final localPlays = await PlaysSQL.getAllPlays(oldestDate, lastDate);
  for (var localPlay in localPlays) {
    if (!bggPlays.map((e) => e.id).contains(localPlay.id)) {
      log("Delete obsolete play ${localPlay.id}");
      PlaysSQL.deletePlay(localPlay);
    }
  }
}

Future<bool> checkLoginByRequest(String username, String password) async {
  dynamic bodyLogin = json.encode({
    'credentials': {'username': username, 'password': password}
  });

  var response = await http
      .post(Uri.parse("https://boardgamegeek.com/login/api/v1"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: bodyLogin)
      .timeout(requestTimeout);
  if (response.hasError) {
    return false;
  } else {
    return true;
  }
}

Future<bool> checkLoginFromStorage() async {
  const storage = FlutterSecureStorage();
  var username = await storage.read(key: "username");
  var password = await storage.read(key: "password");

  if (password == null || username == null) {
    return false;
  }

  // Offline mode
  final hasConnection = await checkInternetConnection();
  if (!hasConnection) {
    return true;
  }

  return await checkLoginByRequest(username, password);
}

Future<List<Map>> getAllPlayers() async {
  var playersMap = await PlayersSQL.getAllPlayers();
  return playersMap;
}

Future<List<Map>> getLocalLocations() async {
  var locationsMap = await LocationSQL.getAllLocations();
  return locationsMap;
}

Future<List<Location>> getLocalLocationsObj() async {
  return await LocationSQL.getAllLocationsObj();
}

Future<Location?> getDefaultLocation() async {
  return await LocationSQL.getDefaultLocation();
}

Future<void> sendOfflinePlaysToBGG() async {
  var offlinePlays = await PlaysSQL.selectOfflineLoggedPlays();
  if (offlinePlays.isEmpty) {
    return;
  }
  for (var offlinePlay in offlinePlays) {
    await sendLogPlayToBGG(offlinePlay);
    await PlaysSQL.deletePlay(offlinePlay);
    // ANTI DDOS
    await Future.delayed(Duration(milliseconds: loadTimeoutMs));
  }
}

List<Map<String, dynamic>> parseBggPlayers(String input) {
  List<String> playerStrings = input.split(';');

  const fields = [
    'username',
    'userid',
    'name',
    'startposition',
    'color',
    'score',
    'new',
    'rating',
    'win'
  ];

  List<Map<String, dynamic>> players = [];

  for (String playerStr in playerStrings) {
    List<String> values = playerStr.split('|');

    Map<String, dynamic> player = {};

    for (int i = 0; i < fields.length; i++) {
      String field = fields[i];

      String value = (i < values.length) ? values[i] : "";

      if (field == 'win') {
        player[field] = (value == "1") ? true : false;
      } else {
        player[field] = value;
      }
    }

    players.add(player);
  }

  return players;
}

Future<void> initializeBggData(
    LoadingStatus loadingStatus, dynamic context, refreshProgress) async {
  loadingStatus.status = S.of(context).updatingGameCollection;
  isLoadedGamesPlayersCountInfoNotifier.value =
      await checkAllGamesCountInfoLoaded();
  isLoadedAllGamesImagesNotifier.value = await checkAllGamesImagesLoaded();

  await importGameCollectionFromBGG(refreshProgress);

  refreshProgress(true, S.of(context).updatingPlaysInfo);
  // int maxPlayerId = await PlayersSQL.getMaxID();
  // int maxLocationId = await LocationSQL.getMaxID();
  //await getPlaysFromPage(1, maxPlayerId, maxLocationId);
  await getAllPlaysFromServer();

  await getGamesThumbnail(refreshProgress, context);
  await getGamesPlayersCount(refreshProgress, context);
  TaskChecker().needCancel = false;
}

Future<String> sendLogPlayToBGG(BggPlay bggPlay) async {
  var logData = {
    "playdate": "2024-03-15",
    "comments": "#$appName",
    "length": 60,
    "twitter": "false",
    "minutes": 60,
    "location": "Home",
    "objectid": "158899",
    "hours": 0,
    "quantity": "1",
    "action": "save",
    "date": "2024-02-28T05:00:00.000Z",
    "players": [],
    "objecttype": "thing",
    "ajax": 1
  };

  final players =
      bggPlay.players == null ? [] : parseBggPlayers(bggPlay.players!);

  logData['players'] = players;
  logData['objectid'] = bggPlay.gameId;
  logData['length'] = bggPlay.duration ?? 0;
  logData['playdate'] = bggPlay.date;
  logData['date'] = "${bggPlay.date}T05:00:00.000Z";
  logData['comments'] = bggPlay.comments ?? "";
  logData['location'] = bggPlay.location ?? "";
  String stringData = json.encode(logData);

  return await sendLogRequest(stringData);
}

Future<String> sendLogRequest(String logData) async {
  dynamic bodyLogin = json.encode({
    'credentials': {
      'username': LoginHandler().login,
      'password': LoginHandler().getDecryptedPassword()
    }
  });

  var loginResponse =
      await http.post(Uri.parse("https://boardgamegeek.com/login/api/v1"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: bodyLogin);
  String sessionCookie = '';
  for (final cookie in loginResponse.headers['set-cookie']!.split(';')) {
    if (cookie.startsWith('bggusername')) {
      sessionCookie += '${cookie.isNotEmpty ? ' ' : ''}$cookie;';
      continue;
    }
    var idx = cookie.indexOf('bggpassword=');
    if (idx != -1) {
      sessionCookie +=
          '${cookie.isNotEmpty ? ' ' : ''}bggpassword=${cookie.substring(idx + 12)};';
      continue;
    }
    idx = cookie.indexOf('SessionID=');
    if (idx != -1) {
      sessionCookie +=
          '${cookie.isNotEmpty ? ' ' : ''}SessionID=${cookie.substring(idx + 10)};';
      continue;
    }
  }

  var resp2 =
      await http.post(Uri.parse("https://boardgamegeek.com/geekplay.php"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'cookie': sessionCookie,
          },
          body: logData);
  print(resp2.body);
  if (resp2.statusCode == 200) {
    try {
      Map<String, dynamic> jsonData = jsonDecode(resp2.body);

      String playid = jsonData['playid'] as String;
      return playid;
    } catch (e) {
      return e.toString();
    }
  }
  return "Error";
}

Future<List<GameThing>?> searchGamesFromLocalDB(String searchString) async {
  List<GameThing> games = [];
  var allGames = await GameThingSQL.getAllGames();
  if (allGames == null) {
    return games;
  }

  if (searchString.isEmpty) {
    return allGames;
  }

  for (var game in allGames) {
    if (game.name.toLowerCase().contains(searchString.toLowerCase())) {
      games.add(game);
    }
  }
  return games;
}

Map<String, String> createBggPlayersInfo(List<Map<dynamic, dynamic>> players) {
  Map<String, String> playersInfo = {};
  if (players.isEmpty) {
    return playersInfo;
  }

  var playerIndex = 0;
  for (var player in players.where((e) => e['isChecked'] == true)) {
    // Structure of player:
    // (0) username="" | (1) userid="0" | (2) name="Саша" | (3) startposition=""
    //| (4) color="" | (5) score="42" | (6) new="0" | (7) rating="0" | (8) win="1"
    if (player['username'] != "") {
      // Bgg player
      var bggPlayerInfo =
          players.where((e) => e["username"] == player['username']).first;

      playersInfo['players[$playerIndex][username]'] =
          player['username'].toString();
      playersInfo['players[$playerIndex][name]'] = player['name'].toString();
      playersInfo['players[$playerIndex][win]'] =
          player['win'] == true ? "1" : "0";
      playersInfo['players[$playerIndex][score]'] =
          bggPlayerInfo["score"].toString();
      playersInfo['players[$playerIndex][new]'] =
          bggPlayerInfo["new"].toString();
      playersInfo['players[$playerIndex][color]'] =
          bggPlayerInfo["color"].toString();
      playersInfo['players[$playerIndex][rating]'] =
          bggPlayerInfo["rating"].toString();
      playersInfo['players[$playerIndex][startposition]'] =
          bggPlayerInfo["startposition"].toString();
    } else {
      // Offline player
      var bggPlayerInfo = players
          .where((e) => e["name"] == player['name'] && player['username'] == "")
          .first;
      playersInfo['players[$playerIndex][name]'] = player['name'].toString();
      playersInfo['players[$playerIndex][win]'] =
          player['win'] == true ? "1" : "0";
      playersInfo['players[$playerIndex][score]'] =
          bggPlayerInfo["score"].toString();
      playersInfo['players[$playerIndex][new]'] =
          bggPlayerInfo["new"].toString();
      playersInfo['players[$playerIndex][color]'] =
          bggPlayerInfo["color"].toString();
      playersInfo['players[$playerIndex][rating]'] =
          bggPlayerInfo["rating"].toString();
      playersInfo['players[$playerIndex][startposition]'] =
          bggPlayerInfo["startposition"].toString();
    }
    playerIndex++;
  }
  return playersInfo;
}

Map<String, Object?> createFormData(
    BggPlay play,
    String playdate,
    String location,
    String comments,
    String duration,
    Map<String, String> players) {
  final formData = {
    'version': '2',
    'objecttype': 'thing',
    'objectid': play.gameId.toString(), // ID игры (Abyss)
    'playid': play.id.toString(), // ID редактируемой партии
    'action': 'save', // Обязательное действие
    'playdate': playdate, // Дата в формате YYYY-MM-DD
    'location': location, // Место проведения
    'quantity': '1', // Количество игр
    'incomplete': play.incomplete.toString(), // ID редактируемой партии
    'nowinstats': play.nowinstats.toString(),
    'length': duration, // Длительность в минутах
    'comments': comments, // Комментарий
  };
  if (play.players == null) {
    return formData;
  }

  formData.addAll(players);

  return formData;
}

Future<String> editBGGPlay(String playId, Map<String, Object?> formData) async {
  final username = LoginHandler().login;
  final password = LoginHandler().getDecryptedPassword();
  final client = http.Client();
  String errorMessage = '';

  try {
    print('Шаг 1: Авторизация...');
    final loginResponse = await client.post(
      Uri.parse('https://boardgamegeek.com/login/api/v1'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'credentials': {'username': username, 'password': password}
      }),
    );

    String sessionCookie = '';
    for (final cookie in loginResponse.headers['set-cookie']!.split(';')) {
      if (cookie.startsWith('bggusername')) {
        sessionCookie += '${cookie.isNotEmpty ? ' ' : ''}$cookie;';
        continue;
      }
      var idx = cookie.indexOf('bggpassword=');
      if (idx != -1) {
        sessionCookie +=
            '${cookie.isNotEmpty ? ' ' : ''}bggpassword=${cookie.substring(idx + 12)};';
        continue;
      }
      idx = cookie.indexOf('SessionID=');
      if (idx != -1) {
        sessionCookie +=
            '${cookie.isNotEmpty ? ' ' : ''}SessionID=${cookie.substring(idx + 10)};';
        continue;
      }
    }

    print('Шаг 3: Отправка изменений...');
    final updateUrl = Uri.parse('https://boardgamegeek.com/geekplay.php');
    final updateResponse = await client.post(
      updateUrl,
      headers: {
        'cookie': sessionCookie,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Origin': 'https://boardgamegeek.com',
        'Referer': 'https://boardgamegeek.com/play/edit/$playId',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...',
      },
      body: formData,
    );

    // 6. Проверка результата
    if (updateResponse.statusCode == 302) {
      print('✓ Успех! Сервер выполнил перенаправление');
    } else if (updateResponse.body.contains('Play recorded successfully')) {
      print('✓ Изменения сохранены!');
    } else {
      errorMessage = "Cannot update game play, try later";
    }
  } catch (e) {
    errorMessage = e.toString();
  } finally {
    client.close();
  }
  return errorMessage;
}

Future<String> getCsrfToken(http.Client client) async {
  final url = Uri.parse('https://boardgamegeek.com/plays');
  final response = await client.get(url);
  final document = parser.parse(response.body);

  final tokenElement = document.querySelector('input[name="token"]');
  return tokenElement?.attributes['value'] ?? '';
}

Future<String> authenticate() async {
  final url = Uri.parse('https://boardgamegeek.com/login');
  final response = await http.post(
    url,
    body: {
      'username': LoginHandler().login,
      'password': LoginHandler().getDecryptedPassword(),
      'redirect': '1',
    },
  );

  // Проверяем успешный вход (куки сохранятся в client)
  if (response.statusCode == 200) {
    return response.headers['set-cookie']!;
  } else {
    throw Exception('Ошибка аутентификации');
  }
}

Future<List<GameThing>?> searchGamesFromBGG(String searchString) async {
  List<GameThing> games = [];
  if (searchString.isEmpty) {
    return games;
  }

  var response = await http.get(
      Uri.parse(
          "https://boardgamegeek.com/xmlapi2/search?query=$searchString&type=boardgame"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $bearerToken',
      });

  final rootNode = xml.XmlDocument.parse(response.body);

  if (rootNode.findElements('items').isEmpty) return games;
  final itemsNode = rootNode.findElements('items').first;
  final items = itemsNode.findElements('item');
  for (final item in items) {
    final objectId = int.parse(item.getAttribute('id').toString());

    final objectNameNode = item.findElements('name').first;
    final objectName = objectNameNode.getAttribute('value').toString();
    final objectType = objectNameNode.getAttribute('type').toString();
    final yearpublishedNode = item.findElements('yearpublished').firstOrNull;
    String? yearpublished;
    if (yearpublishedNode != null) {
      yearpublished = yearpublishedNode.getAttribute('value').toString();
    }
    if (objectType == 'primary') {
      if (objectName
          .toLowerCase()
          .contains(RegExp('^${searchString.toLowerCase()}'))) {
        games.add(GameThing(
            name: objectName,
            id: objectId,
            thumbnail: "",
            image: "",
            minPlayers: 1, // doesnt matter
            maxPlayers: 1, // doesnt matter
            owned: 0, // doesnt matter
            yearpublished: yearpublished));
      }
    }
  }

  return games;
}

Future<String> _getSessionCookie() async {
  dynamic bodyLogin = json.encode({
    'credentials': {
      'username': LoginHandler().login,
      'password': LoginHandler().getDecryptedPassword()
    }
  });

  var loginResponse = await http.post(
    Uri.parse("https://boardgamegeek.com/login/api/v1"),
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: bodyLogin,
  );

  String sessionCookie = '';
  String cookieValue = '';
  for (final cookie in loginResponse.headers['set-cookie']!.split(';')) {
    if (cookie.startsWith('bggusername')) {
      sessionCookie += '${cookie.isNotEmpty ? ' ' : ''}$cookie;';
      continue;
    }
    var idx = cookie.indexOf('bggpassword=');
    if (idx != -1) {
      cookieValue = cookie.substring(idx + 12);
      if (cookieValue != 'deleted')
        sessionCookie +=
            '${cookie.isNotEmpty ? ' ' : ''}bggpassword=$cookieValue;';
      continue;
    }
    idx = cookie.indexOf('SessionID=');
    if (idx != -1) {
      cookieValue = cookie.substring(idx + 10);
      if (cookieValue != 'deleted')
        sessionCookie +=
            '${cookie.isNotEmpty ? ' ' : ''}SessionID=$cookieValue;';
      continue;
    }
  }

  return sessionCookie;
}

Future<bool> checkInternetConnection() async {
  //return false;
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.mobile)) {
    return true;
  } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
    return true;
  } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
    return true;
  }
  return false;
}
