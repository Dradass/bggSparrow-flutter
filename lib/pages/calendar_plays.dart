import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import '../widgets/calendar_month.dart';
import '../models/bgg_play_model.dart';
import '../models/bgg_play_player.dart';

import '../s.dart';
import 'package:intl/intl.dart';
import '../widgets/common.dart';
import '../pages/edit_play.dart';

import '../db/plays_sql.dart';
import '../db/game_things_sql.dart';
import 'dart:convert';

class CalendarPlays extends StatefulWidget {
  final Function(VoidCallback) onRefreshCallbackRegistered;
  const CalendarPlays({required this.onRefreshCallbackRegistered, super.key});

  @override
  State<CalendarPlays> createState() => _CalendarPlaysState();
}

class _CalendarPlaysState extends State<CalendarPlays> {
  late Map<String, List<BggPlay>> groupedDates = {};
  DateTime? startDate = DateTime(2000);
  DateTime? endDate = DateTime(3000);
  late List<BggPlay> allPlays;
  List<Map<BggPlay, GameThing?>> playsOfDay = [];
  final Image imagewidget = Image.asset('assets/no_image.png');
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRefreshCallbackRegistered(_refresh);
    });
    updateAllPlays();
  }

  void _refresh() {
    setState(() {});
  }

  Future<void> updateAllPlays() async {
    PlaysSQL.getAllPlays(startDate, endDate).then((allPlays) {
      for (var play in allPlays.reversed) {
        var playDate = DateTime.parse(play.date);
        var keyDate = DateTime(playDate.year, playDate.month, 1);
        var keyDateString = keyDate.toString();

        if (!groupedDates.containsKey(keyDateString)) {
          groupedDates[keyDateString] = [];
        }
        groupedDates[keyDateString]!.add(play);
      }
    });
  }

  List<String> getYearsList() {
    Set<String> years = {};
    for (var key in groupedDates.keys) {
      DateTime date = DateTime.parse(key);
      years.add(date.year.toString());
    }
    var list = years.toList()..sort((a, b) => b.compareTo(a));
    list.insert(0, S.of(context).all);
    return list;
  }

  Map<String, List<BggPlay>> getFilteredDates(String? selectedYear) {
    if (selectedYear == S.of(context).all || selectedYear == null) {
      return groupedDates;
    }

    Map<String, List<BggPlay>> filtered = {};
    for (var entry in groupedDates.entries) {
      DateTime date = DateTime.parse(entry.key);
      if (date.year.toString() == selectedYear) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  void _showContextMenu(
      BggPlay play, BuildContext context, Offset tapPosition) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 30, 30),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: S.of(context).edit,
          child: Text(S.of(context).edit),
        ),
      ],
    ).then((value) {
      if (value == S.of(context).edit) {
        print('Edit pressed for: ${play.gameName}');
        if (play == null) {
          showSnackBar(context, S.of(context).gamePlayWasNotFound);
        } else {
          showDialog(
              context: context,
              builder: (buildContext) {
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                      title: Text(S.of(context).editPlayData),
                      content: EditPage(
                          bggPlay: play, playsRefreshCallback: updateAllPlays));
                });
              });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final yearsList = getYearsList();
    String? selectedYear = S.of(context).all;
    final filteredDates = getFilteredDates(selectedYear);

    return Column(children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.025),
      SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: SingleChildScrollView(
            child: Column(
              children: filteredDates.entries.map((entry) {
                List<String> parts = entry.key.split('-');
                int year = int.parse(parts[0]);
                int month = int.parse(parts[1]);

                return Column(
                  children: [
                    CalendarWidget(
                      year: year,
                      month: month,
                      bggPlays: entry.value,
                      selectedDate: selectedDate,
                      onDateTap: (date, playsForDate) async {
                        setState(() {
                          selectedDate = date;
                        });
                        playsOfDay.clear();

                        for (var play in playsForDate) {
                          var game =
                              await GameThingSQL.selectGameByID(play.gameId);
                          playsOfDay.add({play: game});
                          debugPrint('  - ${play.gameName}');
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
          )),
      Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: selectedYear,
            items: yearsList.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedYear = newValue;
                selectedDate =
                    null; // Сбрасываем выбранную дату при изменении года
                playsOfDay.clear();
              });
            },
          ),
          SizedBox(width: 10),
          selectedDate == null
              ? Text(
                  S.of(context).selectTheDate,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                )
              : Text(
                  "${DateFormat('dd MMMM', S.currentLocale.languageCode).format(selectedDate!)}, ${S.of(context).results}:",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                )
        ],
      ),
      Expanded(
          child: SingleChildScrollView(
              child: Column(
                  children: playsOfDay.map((play) {
        return Builder(builder: (context) {
          return GestureDetector(
              onTapDown: (TapDownDetails details) {
                _showContextMenu(
                  play.keys.first,
                  context,
                  details.globalPosition,
                );
              },
              child: Column(children: [
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.25,
                        child: play.values.first != null &&
                                play.values.first!.thumbBinary != null
                            ? Image.memory(
                                base64Decode(play.values.first!.thumbBinary!))
                            : Image.asset('assets/no_image.png')),
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Text(
                          play.keys.first.gameName,
                          textAlign: TextAlign.center,
                        )),
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        child: getPlayersColumn(play.keys.first, context))
                  ],
                )
              ]));
        });
      }).toList())))
    ]);
  }
}

Column getPlayersColumn(BggPlay bggPlay, BuildContext context) {
  final players = bggPlay.players;
  if (players == null || players.isEmpty) {
    return const Column(children: []);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: players.split(';').map((playerInfo) {
      final player = BggPlayPlayer.fromString(playerInfo);
      final playerName = player.userid == "0"
          ? player.name
          : "${player.name} (${player.username})";

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: player.win == '1'
            ? _buildWinnerRow(playerName, context)
            : _buildNormalRow(playerName),
      );
    }).toList(),
  );
}

Widget _buildWinnerRow(String playerName, BuildContext context) {
  return Container(
    constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, color: Colors.amber, size: 15),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            playerName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    ),
  );
}

Widget _buildNormalRow(String playerName) {
  return IntrinsicWidth(
    child: Text(
      playerName,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
  );
}
