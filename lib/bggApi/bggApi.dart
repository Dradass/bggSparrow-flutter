import 'package:flutter_application_1/models/game_thing.dart';
import '../db/game_things_sql.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

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
