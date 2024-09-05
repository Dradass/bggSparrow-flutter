import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/main.dart';
import '../db/location_sql.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../widgets/log_page_widgets.dart';
import '../widgets/camera_handler.dart';

class PlaySender extends StatefulWidget {
  static PlaySender? _singleton;

  factory PlaySender(SearchController searchController) {
    _singleton ??= PlaySender._internal(searchController);
    return _singleton!;
  }

  PlaySender._internal(this.searchController);
  SearchController searchController;
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

  @override
  State<PlaySender> createState() => _PlaySenderState();
}

class _PlaySenderState extends State<PlaySender> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          if (CameraHandler(widget.searchController, cameras)
                  .recognizedGameId <=
              0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No game was chosen to log play'),
            ));
          }
          List<Map> bggPlayers = [];
          for (var player in PlayersPicker()
              .players
              .where((element) => element['isChecked'] == true)) {
            bggPlayers.add({
              'username': player['username'],
              'userid': player['userid'],
              'name': player['name'],
              'win': player['win'] ? 1 : 0
            });
          }
          widget.logData['players'] = bggPlayers;
          widget.logData['objectid'] =
              CameraHandler(widget.searchController, cameras).recognizedGameId;
          widget.logData['length'] =
              DurationSliderWidget().durationCurrentValue;
          widget.logData['playdate'] =
              DateFormat('yyyy-MM-dd').format(PlayDatePicker().playDate);
          widget.logData['date'] =
              "${DateFormat('yyyy-MM-dd').format(PlayDatePicker().playDate)}T05:00:00.000Z";
          widget.logData['comments'] = Comments().commentsController.text;

          var chosenLocation = await LocationSQL.selectLocationByName(
              LocationPicker().selectedLocation);
          print(chosenLocation);
          widget.logData['location'] =
              chosenLocation != null ? chosenLocation.name : "";
          String stringData = json.encode(widget.logData);
          print(stringData);
          await sendLogRequest(stringData);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Request was sent'),
          ));
        },
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
                Theme.of(context).colorScheme.secondary),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: const Text("Log play"),
        icon: const Icon(Icons.send_and_archive));
  }
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
