import 'package:flutter_application_1/models/game_thing.dart';
import '../db/game_things_sql.dart';
import '../db/players_sql.dart';
import '../db/plays_sql.dart';
import '../db/location_sql.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/bgg_player_model.dart';
import '../models/bgg_play_model.dart';
import '../models/bgg_location.dart';

Future<void> ImportGameCollectionFromBGG() async {
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
      final gameThingResponse = await http.get(
          Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=$objectId'));
      if (gameThingResponse.statusCode == 200) {
        final gameThingServer = GameThing.fromXml(gameThingResponse.body);
        minPlayers = gameThingServer.minPlayers;
        maxPlayers = gameThingServer.maxPlayers;
      }
      GameThing gameThing = GameThing(
          name: objectName,
          id: objectId,
          thumbnail: thumbnail,
          image: image,
          minPlayers: minPlayers,
          maxPlayers: maxPlayers,
          owned: owned);
      GameThingSQL.addGame(gameThing);
    }
  }
  final gamesCount = await GameThingSQL.getAllGames();
  print("-----finished adding games");
  final gettingAllGames = await GameThingSQL.getAllGames();
  if (gettingAllGames != null) {
    for (var game in gettingAllGames) {
      if (game.thumbBinary == null) game.CreateBinaryThumb();
    }
  }
  // gettingAllGames.then((allGames) {
  //   if (allGames != null) {
  //     for (var game in allGames) {
  //       if (game.thumbBinary == null) game.CreateBinaryThumb();
  //     }
  //     print("-----finished adding thumbs");
  //   }
  // });
}

Future<void> getAllPlaysFromServer() async {
  const maxPagesCount = 1000;
  int maxPlayerId = await PlayersSQL.getMaxID();
  int maxLocationId = await LocationSQL.getMaxID();

  for (var i = 1; i < maxPagesCount; i++) {
    var stillHavePlays = await getPlaysFromPage(i, maxPlayerId, maxLocationId);
    if (!stillHavePlays) break;
  }
}

Future<bool> getPlaysFromPage(
    int pageNumber, int maxPlayerId, maxLocationId) async {
  const userName = 'dradass';

  List<Player> uniquePlayers = [];
  List<int> winnersId = [];
  List<Location> uniqueLocations = [];
  List<BggPlay> bggPlays = [];

  print("create players, iteration = $pageNumber");
  final collectionResponse = await http.get(Uri.parse(
      'https://boardgamegeek.com/xmlapi2/plays?username=$userName&page=$pageNumber'));
  final rootNode = xml.XmlDocument.parse(collectionResponse.body);
  if (rootNode.findElements('plays').isEmpty) return false;
  final playsRoot = rootNode.findElements('plays').first;
  final plays = playsRoot.findElements('play');

  if (plays.isEmpty) return false;

  print("plays count = ${plays.length}");

  for (var play in plays) {
    winnersId = [];
    final objectId = int.parse(play.getAttribute('id').toString());
    print("objectId = $objectId");
    final date = play.getAttribute('date').toString();
    final location = play.getAttribute('location').toString();
    final duration = int.parse(play.getAttribute('length').toString());
    final quantity = int.parse(play.getAttribute('quantity').toString());
    final comments = play.findElements('comments').firstOrNull != null
        ? play.findElements('comments').first.text
        : "";
    final gameId = int.parse(
        play.findElements('item').first.getAttribute('objectid').toString());

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
      for (var player in players) {
        if (player.getAttribute('name') == null) continue;
        var newPlayer = Player(
          id: maxPlayerId,
          name: player.getAttribute('name').toString(),
          userid: int.parse(player.getAttribute('userid').toString()),
          username: player.getAttribute('username').toString(),
        );
        var win = player.getAttribute('win').toString();

        if (!uniquePlayers.map((e) => e.name).contains(newPlayer.name)) {
          if ((newPlayer.userid != 0 &&
                  await PlayersSQL.selectPlayerByUserID(newPlayer.userid!) ==
                      null) ||
              newPlayer.userid == 0) {
            if (await PlayersSQL.selectPlayerByName(newPlayer.name) == null) {
              uniquePlayers.add(newPlayer);

              if (win == '1') {
                winnersId.add(maxPlayerId);
              }
            }
          }
        }
      }
    }
    var bggPlay = BggPlay(
        id: objectId,
        gameId: gameId,
        date: date,
        comments: comments,
        duration: duration,
        quantity: quantity,
        location: location,
        winners: winnersId.join(';'),
        players: uniquePlayers.map((e) => e.id).join(';'));
    print("bgg play new = $objectId");
    if (await PlaysSQL.selectPlayByID(bggPlay.id) == null) {
      bggPlays.add(bggPlay);
      print("bgg play added = $objectId");
    }
  }
  print("bggPlays count = ${bggPlays.length}");
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
  print("creating bgg plays count = ${bggPlays.length}");
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

Future<void> initializeBggData() async {
  await ImportGameCollectionFromBGG();
  int maxPlayerId = await PlayersSQL.getMaxID();
  int maxLocationId = await LocationSQL.getMaxID();
  await getPlaysFromPage(1, maxPlayerId, maxLocationId);
}
