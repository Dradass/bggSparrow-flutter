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

Future<void> getGamesInfoFromBgg(refreshProgress) async {
  await ImportGameCollectionFromBGG(refreshProgress);
  await getGamesThumbnail(refreshProgress);
  await getGamesPlayersCount(refreshProgress);
}

Future<void> ImportGameCollectionFromBGG(refreshProgress) async {
  await GameThingSQL.createTable();
  final collectionResponse = await http.get(Uri.parse(
      'https://boardgamegeek.com/xmlapi2/collection?username=dradass'));

  if (collectionResponse.statusCode == 200) {
    final rootNode = xml.XmlDocument.parse(collectionResponse.body);
    final itemsNode = rootNode.findElements('items').first;
    final items = itemsNode.findElements('item');
    for (final item in items) {
      final objectId = int.parse(item.getAttribute('objectid').toString());
      if (await GameThingSQL.selectGameByID(objectId) != null) continue;
      final objectName = item.findElements('name').first.text;
      final thumbnail = item.findElements('thumbnail').first.text;
      final image = item.findElements('image').first.text;
      final owned = int.parse(
          item.findElements('status').first.getAttribute('own').toString());
      var minPlayers = 0;
      var maxPlayers = 0;
      print("Importing game $objectName");
      refreshProgress(true, "Importing game $objectName");

      // Anti DDOS
      // await Future.delayed(const Duration(milliseconds: 1000));

      // final gameThingResponse = await http.get(
      //     Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=$objectId'));
      // if (gameThingResponse.statusCode == 200) {
      //   final gameThingServer = GameThing.fromXml(gameThingResponse.body);
      //   minPlayers = gameThingServer.minPlayers;
      //   maxPlayers = gameThingServer.maxPlayers;
      // } else {
      //   print("Error while getting info about game $objectName id = $objectId");
      //   continue;
      // }
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
  // final gamesCount = await GameThingSQL.getAllGames();
  // print("-----finished adding games");
  // final gettingAllGames = await GameThingSQL.getAllGames();
  // if (gettingAllGames != null) {
  //   for (var game in gettingAllGames) {
  //     if (game.thumbBinary == null) game.CreateBinaryThumb();
  //   }
  // }
}

Future<void> getGamesThumbnail(refreshProgress) async {
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames != null) {
    int gamesWithThumbCount = gettingAllGames
        .where((e) => e.thumbBinary != null && e.thumbBinary!.isNotEmpty)
        .length;
    for (var game in gettingAllGames) {
      if (game.thumbBinary == null) {
        game.CreateBinaryThumb();
        refreshProgress(true,
            "Creating thumbnails. $gamesWithThumbCount / ${gettingAllGames.length - 1}");
        gamesWithThumbCount += 1;
        // Anti DDOS
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    }
  }
}

Future<void> getGamesPlayersCount(refreshProgress) async {
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames != null) {
    int gamesWithPlayerInfo = gettingAllGames
        .where((e) => e.minPlayers != 0 && e.maxPlayers != 0)
        .length;
    for (var game in gettingAllGames) {
      if (game.minPlayers != 0 && game.maxPlayers != 0) continue;

      var client = RetryClient(http.Client(), retries: 5);
      var gameThingResponse = await client.get(
          Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=${game.id}'));
      client.close();

      // final gameThingResponse = await http.get(
      //     Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=${game.id}'));
      if (gameThingResponse.statusCode == 200) {
        final gameThingServer = GameThing.fromXml(gameThingResponse.body);
        game.minPlayers = gameThingServer.minPlayers;
        game.maxPlayers = gameThingServer.maxPlayers;
        print("Update players count of game ${game.name} id = ${game.id}");
        refreshProgress(true,
            "Update players game info. $gamesWithPlayerInfo / ${gettingAllGames.length - 1}");
        gamesWithPlayerInfo += 1;
        await GameThingSQL.updateGame(game);
        // Anti DDOS
        await Future.delayed(const Duration(milliseconds: 2000));
      } else {
        print(
            "Error while getting info about game ${game.name} id = ${game.id}");
      }
    }
  }
}

Future<void> getAllPlaysFromServer() async {
  const maxPagesCount = 1000;

  for (var i = 1; i < maxPagesCount; i++) {
    int maxPlayerId = await PlayersSQL.getMaxID();
    int maxLocationId = await LocationSQL.getMaxID();
    var stillHavePlays = await getPlaysFromPage(i, maxPlayerId, maxLocationId);
    if (!stillHavePlays) break;
  }
}

Future<bool> getPlaysFromPage(
    int pageNumber, int maxPlayerId, maxLocationId) async {
  const userName = 'dradass';

  List<Player> uniquePlayers = [];
  List<Player> currentPlayers = [];
  List<String> winnersNames = [];
  List<Location> uniqueLocations = [];
  List<BggPlay> bggPlays = [];

  print("getPlaysFromPage. create players, iteration = $pageNumber");
  final collectionResponse = await http.get(Uri.parse(
      'https://boardgamegeek.com/xmlapi2/plays?username=$userName&page=$pageNumber'));
  final rootNode = xml.XmlDocument.parse(collectionResponse.body);
  if (rootNode.findElements('plays').isEmpty) return false;
  final playsRoot = rootNode.findElements('plays').first;
  final plays = playsRoot.findElements('play');

  if (plays.isEmpty) return false;

  print("getPlaysFromPage. plays count = ${plays.length}");

  for (var play in plays) {
    winnersNames = [];
    final objectId = int.parse(play.getAttribute('id').toString());
    final date = play.getAttribute('date').toString();
    final location = play.getAttribute('location').toString();
    final duration = int.parse(play.getAttribute('length').toString());
    final quantity = int.parse(play.getAttribute('quantity').toString());
    final comments = play.findElements('comments').firstOrNull != null
        ? play.findElements('comments').first.text
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
    print('winners = {$winnersNames}');
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
  //print(newBggPlayers.map((e) => e.name));
  for (var newPlayer in newBggPlayers) {
    if (await PlayersSQL.selectPlayerByUserID(newPlayer.userid!) != null) {
      print("Exist bgg player ${newPlayer.name}, userid = ${newPlayer.userid}");
    } else {
      print("creating bgg player ${newPlayer.name}");
      maxPlayerId++;
      newPlayer.id = maxPlayerId;
      PlayersSQL.addPlayer(newPlayer);
    }
  }
  var newNotBggPlayers = uniquePlayers.where((element) => element.userid == 0);

  //print(newNotBggPlayers.map((e) => e.name));
  for (var newPlayer in newNotBggPlayers) {
    var foundResult = await PlayersSQL.selectPlayerByName(newPlayer.name);
    if (foundResult != null) {
      print("Exist player name ${newPlayer.name}");
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
      print("Existed location: ${newLocation.name}");
    } else {
      print("New location :${newLocation.name}");
      maxLocationId++;
      newLocation.id = maxLocationId;
      newLocation.isDefault = 0;
      LocationSQL.addLocation(newLocation);
    }
  }
}

Future<void> fillLocalPlays(List<BggPlay> bggPlays) async {
  for (var bggPlay in bggPlays) {
    print(bggPlay.id);
    if (await PlaysSQL.selectPlayByID(bggPlay.id) != null) {
      print("Existed play: ${bggPlay.id}");
    } else {
      print("New play :${bggPlay.id}");
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
    print("Wrong login");
    return false;
  } else {
    print("Login is correct");
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
  loadingStatus.status = "Starting to import collection from server.";

  await getGamesInfoFromBgg(refreshProgress);
  await ImportGameCollectionFromBGG(refreshProgress);

  refreshProgress(true, "New state");
  int maxPlayerId = await PlayersSQL.getMaxID();
  int maxLocationId = await LocationSQL.getMaxID();
  await getPlaysFromPage(1, maxPlayerId, maxLocationId);

  await getGamesThumbnail(refreshProgress);
  await getGamesPlayersCount(refreshProgress);
  refreshProgress(true, "End");
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
  print("-----start sending");
  dynamic bodyLogin = json.encode({
    'credentials': {'username': 'dradass', 'password': '1414141414'}
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

  ///xmlapi2/search?parameters
  var response = await http.get(
      Uri.parse(
          "https://boardgamegeek.com/xmlapi2/search?query=${searchString}&type=boardgame"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      });

  final rootNode = xml.XmlDocument.parse(response.body);
  final itemsNode = rootNode.findElements('items').first;
  final items = itemsNode.findElements('item');
  for (final item in items) {
    final objectId = int.parse(item.getAttribute('id').toString());

    //if (await GameThingSQL.selectGameByID(objectId) != null) continue;
    final objectNameNode = item.findElements('name').first;
    final objectName = objectNameNode.getAttribute('value').toString();
    final objectType = objectNameNode.getAttribute('type').toString();
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
            owned: 0)); // doesnt matter
      }
    }
  }

  return games;
}

Future<bool> checkInternetConnection() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  //return false;
  if (connectivityResult.contains(ConnectivityResult.mobile)) {
    return true;
  } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
    return true;
  } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
    return true;
  }
  return false;
}
