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
import 'dart:developer';

const maxPagesCount = 1000;

Future<void> importGameCollectionFromBGG(refreshProgress) async {
  await GameThingSQL.createTable();
  final collectionResponse = await http.get(Uri.parse(
      'https://boardgamegeek.com/xmlapi2/collection?username=${LoginHandler().login}'));

  if (collectionResponse.statusCode == 200) {
    final rootNode = xml.XmlDocument.parse(collectionResponse.body);
    final itemsNode = rootNode.findElements('items').first;
    final items = itemsNode.findElements('item');
    for (final item in items) {
      final objectId = int.parse(item.getAttribute('objectid').toString());
      if (await GameThingSQL.selectGameByID(objectId) != null) continue;
      final objectName = item.findElements('name').first.innerText;
      final thumbnail = item.findElements('thumbnail').first.innerText;
      final image = item.findElements('image').first.innerText;
      final owned = int.parse(
          item.findElements('status').first.getAttribute('own').toString());
      var minPlayers = 0;
      var maxPlayers = 0;
      log("Importing game $objectName");
      refreshProgress(true, "Importing game $objectName");

      GameThing gameThing = GameThing(
          name: objectName,
          id: objectId,
          thumbnail: thumbnail,
          image: image,
          minPlayers: minPlayers,
          maxPlayers: maxPlayers,
          owned: owned);
      await GameThingSQL.addGame(gameThing);
    }
  }
}

Future<Map<String, dynamic>> getBggPlayerName(String username) async {
  final getPlayerResponse = await http
      .get(Uri.parse('https://boardgamegeek.com//xmlapi2/user?name=$username'));

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

Future<void> getGamesThumbnail(refreshProgress) async {
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames != null) {
    int gamesWithThumbCount = gettingAllGames
        .where((e) => e.thumbBinary != null && e.thumbBinary!.isNotEmpty)
        .length;
    for (var game in gettingAllGames) {
      log("Task canceled = ${TaskChecker().needCancel}");
      if (TaskChecker().needCancel) {
        return;
      }
      if (game.thumbBinary == null) {
        game.createBinaryThumb();
        refreshProgress(true,
            "Creating thumbnails. $gamesWithThumbCount / ${gettingAllGames.length - 1}");
        gamesWithThumbCount += 1;
        // Anti DDOS
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    }
  }
}

Future<String> getGameThumbFromBGG(int gameId) async {
  var client = RetryClient(http.Client(), retries: 5);
  var gameThingResponse = await client
      .get(Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=$gameId'));
  client.close();

  if (gameThingResponse.statusCode == 200) {
    final gameThingServer = GameThing.fromXml(gameThingResponse.body);
    return gameThingServer.thumbnail;
  } else {
    log("Error getting thumbnail");
    return "";
  }
}

Future<void> getGamesPlayersCount(refreshProgress) async {
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames != null) {
    int gamesWithPlayerInfo = gettingAllGames
        .where((e) => e.minPlayers != 0 && e.maxPlayers != 0)
        .length;
    for (var game in gettingAllGames) {
      if (TaskChecker().needCancel) {
        return;
      }
      if (game.minPlayers != 0 && game.maxPlayers != 0) continue;

      var client = RetryClient(http.Client(), retries: 5);
      var gameThingResponse = await client.get(
          Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=${game.id}'));
      client.close();

      if (gameThingResponse.statusCode == 200) {
        final gameThingServer = GameThing.fromXml(gameThingResponse.body);
        game.minPlayers = gameThingServer.minPlayers;
        game.maxPlayers = gameThingServer.maxPlayers;
        log("Update players count of game ${game.name} id = ${game.id}");
        refreshProgress(true,
            "Update players game info. $gamesWithPlayerInfo / ${gettingAllGames.length - 1}");
        gamesWithPlayerInfo += 1;
        await GameThingSQL.updateGame(game);
        // Anti DDOS
        await Future.delayed(const Duration(milliseconds: 2000));
      } else {
        log("Error while getting info about game ${game.name} id = ${game.id}");
      }
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

  log("getPlaysFromPage. create players, iteration = $pageNumber");
  final collectionResponse = await http.get(Uri.parse(
      'https://boardgamegeek.com/xmlapi2/plays?username=${LoginHandler().login}&page=$pageNumber'));
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
      for (var player in players) {
        if (player.getAttribute('name') == null) continue;
        var newPlayer = Player(
          id: maxPlayerId,
          name: player.getAttribute('name').toString(),
          userid: int.parse(player.getAttribute('userid').toString()),
          username: player.getAttribute('username').toString(),
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
        location: location,
        winners: winnersNames.join(';'),
        players: currentPlayers
            .map((e) => '${e.userid.toString()}|${e.name}')
            .join(';'));
    if (await PlaysSQL.selectPlayByID(bggPlay.id) == null) {
      bggPlays.add(bggPlay);
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
    log(bggPlay.id.toString());
    if (await PlaysSQL.selectPlayByID(bggPlay.id) != null) {
      log("Existed play: ${bggPlay.id}");
    } else {
      log("New play :${bggPlay.id}");
      PlaysSQL.addPlay(bggPlay);
    }
  }
}

Future<bool> checkLoginByRequest(String username, String password) async {
  dynamic bodyLogin = json.encode({
    'credentials': {'username': username, 'password': password}
  });

  var response =
      await http.post(Uri.parse("https://boardgamegeek.com/login/api/v1"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: bodyLogin);
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

Future<List<Map>> getLocalPlayers() async {
  var playersMap = await PlayersSQL.getAllPlayers();
  return playersMap;
}

Future<List<Map>> getLocalLocations() async {
  var locationsMap = await LocationSQL.getAllLocations();
  return locationsMap;
}

Future<Location?> fillLocationName() async {
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
    await Future.delayed(const Duration(milliseconds: 2000));
  }
}

Future<void> initializeBggData(
    LoadingStatus loadingStatus, refreshProgress) async {
  loadingStatus.status = "Importing game collection from server.";

  await importGameCollectionFromBGG(refreshProgress);

  refreshProgress(true, "Getting plays info.");
  int maxPlayerId = await PlayersSQL.getMaxID();
  int maxLocationId = await LocationSQL.getMaxID();
  await getPlaysFromPage(1, maxPlayerId, maxLocationId);

  await getGamesThumbnail(refreshProgress);
  await getGamesPlayersCount(refreshProgress);
  TaskChecker().needCancel = false;
}

Future<int> sendLogPlayToBGG(BggPlay bggPlay) async {
  var logData = {
    "playdate": "2024-03-15",
    "comments": "#bggSparrow",
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

  logData['players'] = bggPlay.players ?? "";
  logData['objectid'] = bggPlay.gameId;
  logData['length'] = bggPlay.duration ?? 0;
  logData['playdate'] = bggPlay.date;
  logData['date'] = "${bggPlay.date}T05:00:00.000Z";
  logData['comments'] = bggPlay.comments ?? "";
  logData['location'] = bggPlay.location ?? "";
  String stringData = json.encode(logData);

  return await sendLogRequest(stringData);
}

Future<int> sendLogRequest(String logData) async {
  log("Send log request");
  dynamic bodyLogin = json.encode({
    'credentials': {
      'username': LoginHandler().login,
      'password': LoginHandler().getDecryptedPassword()
    }
  });

  http
      .post(Uri.parse("https://boardgamegeek.com/login/api/v1"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: bodyLogin)
      .then((response) {
    String sessionCookie = '';
    for (final cookie in response.headers['set-cookie']!.split(';')) {
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

    http
        .post(Uri.parse("https://boardgamegeek.com/geekplay.php"),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'cookie': sessionCookie,
            },
            body: logData)
        .then((response2) {});
  });

  return 1;
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
    if (game.name
        .toLowerCase()
        .contains(RegExp('^${searchString.toLowerCase()}'))) {
      games.add(game);
    }
  }
  return games;
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

Future<bool> checkInternetConnection() async {
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
