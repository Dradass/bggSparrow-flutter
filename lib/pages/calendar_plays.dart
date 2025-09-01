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
    // Регистрируем callback в родительском виджете
    // при инициализации дочернего виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRefreshCallbackRegistered(_refresh);
    });
    updateAllPlays();
  }

  void _refresh() {
    print("refresh");
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
          value: 'Edit',
          child: Text('Edit'),
        ),
      ],
    ).then((value) {
      if (value == 'Edit') {
        // Логируем значение gameName
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
                      content: // TODO callback to refresh
                          EditPage(
                              bggPlay: play,
                              playsRefreshCallback: updateAllPlays));
                });
              });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: SingleChildScrollView(
            child: Column(
              children: groupedDates.entries.map((entry) {
                // Получаем год и месяц из ключа
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
                        // Выводим все BggPlay для выбранной даты в лог
                        playsOfDay.clear();

                        debugPrint('BggPlay для выбранной даты:');
                        for (var play in playsForDate) {
                          var game =
                              await GameThingSQL.selectGameByID(play.gameId);
                          playsOfDay.add({play: game});
                          debugPrint('  - ${play.gameName}'); // и другие поля
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20), // Отступ между календарями
                  ],
                );
              }).toList(),
            ),
          )),
      Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          selectedDate == null
              ? Text(
                  "Select the date",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                )
              : Text(
                  "${DateFormat('dd MMMM', S.currentLocale.languageCode).format(selectedDate!)} results:",
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
                // Сохраняем позицию нажатия
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
