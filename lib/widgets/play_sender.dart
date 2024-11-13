import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/game_things_sql.dart';
import 'package:flutter_application_1/db/plays_sql.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/main.dart';
import '../db/location_sql.dart';
import '../db/system_table.dart';
import '../models/bgg_play_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../bggApi/bggApi.dart';

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

  Future<int> sendLogRequestByPlay(BggPlay bggPlay) async {
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
}

class _PlaySenderState extends State<PlaySender> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          var hasInternetConnection = false;
          checkInternetConnection().then((isConnected) => {
                if (isConnected) {hasInternetConnection = true}
              });

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
          final gameId =
              CameraHandler(widget.searchController, cameras).recognizedGameId;
          final dateShort =
              DateFormat('yyyy-MM-dd').format(PlayDatePicker().playDate);
          final duration = DurationSliderWidget().durationCurrentValue.round();
          widget.logData['players'] = bggPlayers;
          widget.logData['objectid'] = gameId;
          widget.logData['length'] = duration;
          widget.logData['playdate'] = dateShort;
          widget.logData['date'] = "${dateShort}T05:00:00.000Z";
          widget.logData['comments'] = Comments().commentsController.text;

          var chosenLocation = await LocationSQL.selectLocationByName(
              LocationPicker().selectedLocation);
          print(chosenLocation);
          widget.logData['location'] =
              chosenLocation != null ? chosenLocation.name : "";
          String stringData = json.encode(widget.logData);
          print(stringData);
          if (!hasInternetConnection) {
            // TODO сохранять данные локально в БД, если нет сети. Отправлять их при старте приложения и наличии сети.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Play has been saved locally and will be sent when the internet is available.')));
            //SystemParameterSQL.addOrUpdateLoggedOfflinePlays();
            final gameThing = await GameThingSQL.selectGameByID(gameId);
            final minFreeId = await PlaysSQL.getMinFreeOfflinePlayId();
            if (minFreeId == null) {
              return;
            }
            print("MIN FREE ID = ${minFreeId}");

            var play = BggPlay(
                id: minFreeId,
                offline: 1,
                gameId: gameId,
                gameName: gameThing?.name ?? "",
                date: dateShort,
                comments: Comments().commentsController.text,
                location: chosenLocation != null ? chosenLocation.name : "",
                players: json.encode(bggPlayers),
                winners: "",
                duration: duration);
            PlaysSQL.addPlay(play);
            return;
          }
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
