import 'dart:math';

import 'package:flutter_application_1/models/game_thing.dart';
import '../db/game_things_sql.dart';
import '../db/players_sql.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/bgg_player_model.dart';

void ImportGameCollectionFromBGG() async {
  final collectionResponse = await http.get(Uri.parse(
      'https://boardgamegeek.com/xmlapi2/collection?username=dradass'));

  if (collectionResponse.statusCode == 200) {
    final rootNode = xml.XmlDocument.parse(collectionResponse.body);
    final itemsNode = rootNode.findElements('items').first;
    final items = itemsNode.findElements('item');
    for (final item in items) {
      final objectId = int.parse(item.getAttribute('objectid').toString());
      final objectName = item.findElements('name').first.text;
      final thumbnail = item.findElements('thumbnail').first.text;
      final image = item.findElements('image').first.text;
      GameThing gameThing = GameThing(
          name: objectName, id: objectId, thumbnail: thumbnail, image: image);
      GameThingSQL.addGame(gameThing);
    }
  }
  ;
  final gamesCount = await GameThingSQL.getAllGames();
  print(gamesCount?.length);
  print("-----finished adding games");
  final gettingAllGames = GameThingSQL.getAllGames();
  gettingAllGames.then((allGames) {
    if (allGames != null) {
      for (var game in allGames) {
        game.CreateBinaryThumb();
      }
      print("-----finished adding thumbs");
    }
  });
}

void GetAllPlaysFromServer() async {
  const max_pages_count = 1000;
  final userName = 'dradass';

  List<Player> uniquePlayers = [];
  // TODO get id from query and db
  int maxPlayerId = await PlayersSQL.getMaxID();
  print("max ID = $maxPlayerId");

  var page = 1;
  final collectionResponse = await http.get(Uri.parse(
      'https://boardgamegeek.com/xmlapi2/plays?username=$userName&page=${page}'));
  final rootNode = xml.XmlDocument.parse(collectionResponse.body);
  final playsRoot = rootNode.findElements('plays').first;
  final plays = playsRoot.findElements('play');
  for (var play in plays) {
    final objectId = int.parse(play.getAttribute('id').toString());
    final date = play.getAttribute('date').toString();
    final location = play.getAttribute('location').toString();
    final quantity = play.getAttribute('quantity').toString();
    final comments = play.findElements('comments');
    final gameId = int.parse(
        play.findElements('item').first.getAttribute('objectid').toString());
    final playersRoot = play.findElements('players').first;
    final players = playersRoot.findElements('player');
    if (players != null) {
      for (var player in players) {
        if (player.getAttribute('name') == null) continue;
        var newPlayer = Player(
          id: maxPlayerId,
          name: player.getAttribute('name').toString(),
          userid: int.parse(player.getAttribute('userid').toString()),
          username: player.getAttribute('username').toString(),
        );
        if (!uniquePlayers.map((e) => e.name).contains(newPlayer.name)) {
          //maxPlayerId++;
          uniquePlayers.add(newPlayer);
        }
      }
    }
    //final players = userName, userId, name, win
  }
  print(uniquePlayers.map((e) => e.name));
  var newBggPlayers = uniquePlayers.where((element) => element.userid != 0);
  print(newBggPlayers.map((e) => e.name));
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

  print(newNotBggPlayers.map((e) => e.name));
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
  //if (playsAll.length == 0) break;
}

Future<List<Map>> FillPlayers() async {
  var playersMap = await PlayersSQL.getAllPlayers();
  print('test');
  print(playersMap);
  return playersMap;
}
