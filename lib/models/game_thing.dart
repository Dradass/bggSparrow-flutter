import 'package:xml/xml.dart' as xml;
import '../db/game_things_sql.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameThing {
  final String name;
  final int id;
  final String thumbnail;
  final String image;
  final String? thumbBinary;

  const GameThing(
      {required this.name,
      required this.id,
      required this.thumbnail,
      required this.image,
      this.thumbBinary});

  factory GameThing.fromJson(Map<String, dynamic> json) {
    return GameThing(
        name: json['name'],
        id: json['id'],
        thumbnail: json['thumbnail'],
        image: json['image'],
        thumbBinary: json['thumbbin']);
  }

  factory GameThing.fromXml(String xmlBody) {
    final document = xml.XmlDocument.parse(xmlBody);
    final itemsNode = document.findElements('items').first;
    final items = itemsNode.findElements('item');

    final item = items.first;
    final itemID = int.parse(item.getAttribute('id').toString());
    final itemName = item
        .findElements('name')
        .where((element) => element.getAttribute('type') == 'primary')
        .first
        .getAttribute('value')
        .toString();
    final thumbnail = item.findElements('thumbnail').first.toString();
    final image = item.findElements('image').first.toString();

    return GameThing(
        name: itemName, id: itemID, thumbnail: thumbnail, image: image);
  }

  factory GameThing.fromXmlCollection(String xmlBody) {
    final document = xml.XmlDocument.parse(xmlBody);
    final itemsNode = document.findElements('items').first;
    final items = itemsNode.findElements('item');

    final item = items.first;
    final itemID = int.parse(item.getAttribute("objectid").toString());
    final itemName = item.findElements('name').first.toString();
    final thumbnail = item.findElements('thumbnail').first.toString();
    final image = item.findElements('image').first.toString();

    return GameThing(
        name: itemName, id: itemID, thumbnail: thumbnail, image: image);
  }

  void CreateBinaryThumb() async {
    http.Response response = await http.get(Uri.parse(thumbnail));
    var imageBytes = response.bodyBytes; //Uint8List
    var bodyBytes = base64Encode(imageBytes);

    final gameThing = GameThing(
        name: name,
        id: id,
        thumbnail: thumbnail,
        image: image,
        thumbBinary: bodyBytes);
    print("Create thumb for $name");
    GameThingSQL.updateGame(gameThing);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'thumbnail': thumbnail,
        'thumbbin': thumbBinary
      };
}
