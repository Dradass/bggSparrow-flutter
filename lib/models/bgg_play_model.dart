import 'package:xml/xml.dart' as xml;
import '../db/game_things_sql.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// final objectId = int.parse(play.getAttribute('id').toString());
// final date = play.getAttribute('date').toString();
// final location = play.getAttribute('location').toString();
// final quantity = play.getAttribute('quantity').toString();
// final gameId = int.parse(play.getAttribute('objectid').toString());
//final players = userName, userId, name, win

class BggPlay {
  final int id;
  final String date;
  final int? quantity;
  final String? location;
  final int gameId;
  final String? comments;
  final String? players;

  const BggPlay(
      {required this.id,
      required this.gameId,
      required this.date,
      this.quantity,
      this.comments,
      this.location,
      this.players});

  // factory GameThing.fromJson(Map<String, dynamic> json) {
  //   return GameThing(
  //       name: json['name'],
  //       id: json['id'],
  //       thumbnail: json['thumbnail'],
  //       image: json['image'],
  //       thumbBinary: json['thumbbin']);
  // }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'gameid': gameId,
        'quantity': quantity,
        'location': location,
        'players': players,
        'comments': comments
      };
}
