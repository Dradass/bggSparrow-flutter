import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/game_things_sql.dart';
import 'package:flutter_application_1/db/plays_sql.dart';
import 'package:flutter_application_1/login_handler.dart';
import 'package:intl/intl.dart';
import '../db/location_sql.dart';
import '../models/bgg_play_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../bggApi/bgg_api.dart';
import '../globals.dart';
import '../widgets/common.dart';
import 'dart:async';
import '../s.dart';

import '../widgets/players_list.dart';

import '../widgets/log_page_widgets.dart';

const fieldOrder = [
  'username',
  'userid',
  'name',
  'startposition',
  'color',
  'score',
  'new',
  'rating',
  'win'
];

class PlaySender extends StatefulWidget {
  static PlaySender? _singleton;

  factory PlaySender(SearchController searchController,
      PlayersListWrapper playersListWrapper) {
    _singleton ??= PlaySender._internal(searchController, playersListWrapper);
    return _singleton!;
  }

  PlaySender._internal(this.searchController, this.playersListWrapper);
  final SearchController searchController;
  PlayersListWrapper playersListWrapper;

  final logData = {
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

  Future<String> sendLogRequestByPlay(BggPlay bggPlay) async {
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
  bool isRequestSending = false;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: isRequestSending
            ? null
            : () async {
                final hasInternetConnection = await checkInternetConnection();

                if (selectedGameId <= 0) {
                  showSnackBar(context, S.of(context).chooseAnyGame);
                  return;
                }
                List<Map> bggPlayers = [];
                String winners = "";
                for (var player in widget.playersListWrapper.players
                    .where((element) => element['isChecked'] == true)) {
                  bggPlayers.add({
                    'username': player['username'],
                    'userid': player['userid'],
                    'name': player['name'],
                    'startposition': "",
                    'color': "",
                    'score': "",
                    'new': "",
                    'rating': "",
                    'win': player['win'] ? 1 : 0
                  });
                  if (player['win']) {
                    winners += "${player['name']};";
                  }
                }
                winners = winners.substring(0, winners.length - 1);
                final gameId = selectedGameId;
                final dateShort =
                    DateFormat('yyyy-MM-dd').format(PlayDatePicker().playDate);
                final duration =
                    DurationSliderWidget().durationCurrentValue.round();
                widget.logData['players'] = bggPlayers;
                widget.logData['objectid'] = gameId;
                widget.logData['length'] = duration;
                widget.logData['incomplete'] = "0";
                widget.logData['nowinstats'] = "0";

                widget.logData['playdate'] = dateShort;
                widget.logData['date'] = "${dateShort}T05:00:00.000Z";
                widget.logData['comments'] = Comments().commentsController.text;

                var chosenLocation = await LocationSQL.selectLocationByName(
                    LocationPicker().selectedLocation);
                widget.logData['location'] =
                    chosenLocation != null ? chosenLocation.name : "";
                String stringData = json.encode(widget.logData);

                setState(() {
                  isRequestSending = true;
                });
                // Log offline if no internet connection
                if (!hasInternetConnection) {
                  showSnackBar(context,
                      S.of(context).resultsAreSavedLocallyAndWillBeSent);
                  final gameThing = await GameThingSQL.selectGameByID(gameId);
                  final minFreeId = await PlaysSQL.getMinFreeOfflinePlayId();
                  if (minFreeId == null) {
                    return;
                  }

                  var play = BggPlay(
                      id: minFreeId,
                      offline: 1,
                      gameId: gameId,
                      gameName: gameThing?.name ?? "",
                      date: dateShort,
                      comments: Comments().commentsController.text,
                      location:
                          chosenLocation != null ? chosenLocation.name : "",
                      players: bggPlayers
                          .map((player) {
                            return fieldOrder
                                .map((field) => player[field]?.toString() ?? "")
                                .join('|');
                          })
                          .toList()
                          .join(";"),
                      winners: winners,
                      duration: duration,
                      incomplete: 0,
                      nowinstats: 0,
                      quantity: 1);
                  PlaysSQL.addPlay(play);
                  Timer(const Duration(seconds: messageDuration + 1), () {
                    setState(() {
                      isRequestSending = false;
                    });
                  });
                  return;
                }
                // Log online if internet connection
                var isOffline = 0;
                var sendLogResult = await sendLogRequest(stringData);
                int? playId = (int.tryParse(sendLogResult));
                if (playId == null) {
                  showSnackBar(context, "NetWork error game saved locally");
                  isOffline = 1;
                  playId = await PlaysSQL.getMinFreeOfflinePlayId();

                  if (playId == null) {
                    showSnackBar(context, "Error saving game, try later");
                    return;
                  }
                }

                final gameThing = await GameThingSQL.selectGameByID(gameId);

                var play = BggPlay(
                    id: playId,
                    offline: isOffline,
                    gameId: gameId,
                    gameName: gameThing?.name ?? "",
                    date: dateShort,
                    comments: Comments().commentsController.text,
                    location: chosenLocation != null ? chosenLocation.name : "",
                    players: bggPlayers
                        .map((player) {
                          return fieldOrder
                              .map((field) => player[field]?.toString() ?? "")
                              .join('|');
                        })
                        .toList()
                        .join(";"),
                    winners: winners,
                    duration: duration,
                    incomplete: 0,
                    nowinstats: 0,
                    quantity: 1);

                PlaysSQL.addPlay(play);
                //needUpdatePlaysFromBgg = true;
                Timer(const Duration(seconds: messageDuration + 1), () {
                  setState(() {
                    isRequestSending = false;
                  });
                });
                showSnackBar(context, S.of(context).playResultsWasSaved);
              },
        style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.secondary),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: Text(S.of(context).logPlay),
        icon: const Icon(Icons.send_and_archive));
  }
}
