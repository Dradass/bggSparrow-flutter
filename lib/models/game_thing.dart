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
  int minPlayers;
  int maxPlayers;
  final int owned;

  GameThing(
      {required this.name,
      required this.id,
      required this.thumbnail,
      required this.image,
      this.thumbBinary,
      required this.minPlayers,
      required this.maxPlayers,
      required this.owned});

  factory GameThing.fromJson(Map<String, dynamic> json) {
    return GameThing(
        name: json['name'],
        id: json['id'],
        thumbnail: json['thumbnail'],
        image: json['image'],
        thumbBinary: json['thumbbin'],
        minPlayers: json['minPlayers'],
        maxPlayers: json['maxPlayers'],
        owned: json['owned']);
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
    final minPlayers = int.parse(
        item.findElements('minplayers').first.getAttribute('value').toString());
    final maxPlayers = int.parse(
        item.findElements('maxplayers').first.getAttribute('value').toString());
    final thumbnail = item.findElements('thumbnail').first.toString();
    final image = item.findElements('image').first.toString();

    return GameThing(
        name: itemName,
        id: itemID,
        thumbnail: thumbnail,
        image: image,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        owned: 0);
  }

  // factory GameThing.fromXmlCollection(String xmlBody) {
  //   final document = xml.XmlDocument.parse(xmlBody);
  //   final itemsNode = document.findElements('items').first;
  //   final items = itemsNode.findElements('item');

  //   final item = items.first;
  //   final itemID = int.parse(item.getAttribute("objectid").toString());
  //   final itemName = item.findElements('name').first.toString();
  //   final thumbnail = item.findElements('thumbnail').first.toString();
  //   final image = item.findElements('image').first.toString();

  //   return GameThing(
  //       name: itemName, id: itemID, thumbnail: thumbnail, image: image);
  // }

  void CreateBinaryThumb() async {
    try {
      http.Response response = await http.get(Uri.parse(thumbnail));
      if (response.statusCode == 200) {
        var imageBytes = response.bodyBytes; //Uint8List
        var bodyBytes = base64Encode(imageBytes);

        final gameThing = GameThing(
            name: name,
            id: id,
            thumbnail: thumbnail,
            image: image,
            thumbBinary: bodyBytes,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            owned: owned);
        print("Create thumb for $name");
        GameThingSQL.updateGame(gameThing);
      } else {
        print("Error while getting thumb: $name");
      }
    } catch (e) {
      print("Error while creating thumb: $e");
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'thumbnail': thumbnail,
        'thumbbin': thumbBinary,
        'minPlayers': minPlayers,
        'maxPlayers': maxPlayers,
        'owned': owned
      };
}
