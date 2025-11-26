import 'package:xml/xml.dart' as xml;
import '../db/game_things_sql.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'dart:convert';
import 'dart:developer';

class GameThing {
  final String name;
  final int id;
  final String thumbnail;
  final String image;
  final String? thumbBinary;
  int minPlayers;
  int maxPlayers;
  final int owned;
  final String? yearpublished;

  GameThing(
      {required this.name,
      required this.id,
      required this.thumbnail,
      required this.image,
      this.thumbBinary,
      required this.minPlayers,
      required this.maxPlayers,
      required this.owned,
      this.yearpublished});

  factory GameThing.fromJson(Map<String, dynamic> json) {
    return GameThing(
        name: json['name'],
        id: json['id'],
        thumbnail: json['thumbnail'],
        image: json['image'],
        thumbBinary: json['thumbbin'],
        minPlayers: json['minPlayers'],
        maxPlayers: json['maxPlayers'],
        owned: json['owned'],
        yearpublished: json['yearpublished']);
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
    // Can be NULL
    final thumbnail = item.findElements('thumbnail').single.innerText;
    final image = item.findElements('image').first.toString();
    final yearpublished = item.findElements('yearpublished').first.toString();

    return GameThing(
        name: itemName,
        id: itemID,
        thumbnail: thumbnail,
        image: image,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        owned: 0,
        yearpublished: yearpublished);
  }

  static Future<String?> getBinaryThumb(String thumbnail) async {
    try {
      var client = RetryClient(http.Client(), retries: 5);
      var response = await client.get(Uri.parse(thumbnail));
      client.close();

      if (response.statusCode == 200) {
        var imageBytes = response.bodyBytes;
        var bodyBytes = base64Encode(imageBytes);
        return bodyBytes;
      }
    } catch (e) {
      log("Error while creating thumb: $e");
    }
    return null;
  }

  Future<void> createBinaryThumb() async {
    try {
      var client = RetryClient(http.Client(), retries: 5);
      var response = await client.get(Uri.parse(thumbnail));
      client.close();

      if (response.statusCode == 200) {
        var imageBytes = response.bodyBytes;
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
        log("Create thumb for $name");
        GameThingSQL.updateGame(gameThing);
      } else {
        log("Error while getting thumb: $name");
      }
    } catch (e) {
      log("Error while creating thumb: $e");
    }
  }

  static bool areEquals(GameThing firstGame, GameThing secondGame) {
    if (firstGame.id == secondGame.id &&
        firstGame.name == secondGame.name &&
        firstGame.thumbnail == secondGame.thumbnail &&
        firstGame.image == secondGame.image &&
        firstGame.owned == secondGame.owned &&
        firstGame.yearpublished == secondGame.yearpublished) return true;
    return false;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'thumbnail': thumbnail,
        'thumbbin': thumbBinary,
        'minPlayers': minPlayers,
        'maxPlayers': maxPlayers,
        'owned': owned,
        'yearpublished': yearpublished
      };
}
