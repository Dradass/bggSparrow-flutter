import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/players_sql.dart';
import 'package:intl/intl.dart';
import '../db/plays_sql.dart';
import '../db/location_sql.dart';
import '../models/bgg_play_model.dart';
import '../bggApi/bgg_api.dart';
import '../db/game_things_sql.dart';
import '../globals.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:developer';

// Free licence for small companies <5 developers and 1 millions $
import 'package:syncfusion_flutter_charts/charts.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  double firstGamesCount = 0;
  List<BggPlay> plays = [];
  Map<int, int> gameThingPlays = {};
  DateTime? startDate = DateTime(2000);
  DateTime? endDate = DateTime(3000);
  var dateFormat = DateFormat('yyyy-MM-dd');
  String statsSummary = "";
  List<_GamePlaysCount> gamePlays = [];
  bool needFilterByGame = false;
  bool winRate = false;
  bool onlyChosenPlayers = false;
  bool winnerAmongChosenPlayers = false;
  RangeValues maxRangeValues = const RangeValues(0, 10);
  List<Map> players = [];
  Map<int, String> chosenGames = {};
  final SearchController searchController = SearchController();
  var chosenGameId = 0;

  DataCell _buildDataCell(
      int rowIndex, int colIndex, Widget child, double? width) {
    return DataCell(
      GestureDetector(
          onLongPressStart: (details) {
            log('long row press: ${plays[rowIndex].id}, playes = ${plays[rowIndex].players}');
            final RenderBox overlay =
                Overlay.of(context).context.findRenderObject()! as RenderBox;
            final RelativeRect position = RelativeRect.fromRect(
              Rect.fromPoints(
                details.globalPosition,
                details.globalPosition + Offset(1, 1),
              ),
              overlay.localToGlobal(Offset.zero) & overlay.size,
            );
            _showContextMenu(context, position);
          },
          child: Container(
            //color: rowIndex.isEven ? Colors.grey[300] : Colors.white,
            width: width,
            child: Builder(
              builder: (cellContext) => Container(
                constraints: const BoxConstraints(minHeight: 45),
                padding: const EdgeInsets.all(3),
                child: child,
              ),
            ),
          )),
    );
  }

  void _showContextMenu(BuildContext context, RelativeRect position) {
    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    ).then((value) {
      if (value == 'delete') {
        // _deleteRow(rowId);
      }
      if (value == 'edit') {
        // _editRow(rowId);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GameThingSQL.getAllGames().then((allGames) {
      chosenGames[0] = "All games";
      if (allGames == null) return;
      for (var game in allGames) {
        chosenGames[game.id] = game.name;
      }
    });

    return Scaffold(
        body: SafeArea(
            child: DefaultTabController(
      length: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const TabBar(tabs: [
            Tab(text: "Plays"),
            Tab(text: "Table"),
            Tab(text: "Histogram"),
            Tab(text: "Piechart"),
          ]),
          LayoutBuilder(builder: ((context, constraints) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.50,
              child: TabBarView(children: [
                SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      headingRowHeight: 0,
                      showCheckboxColumn: false,
                      dataRowMaxHeight: double.infinity,
                      columns: const <DataColumn>[
                        DataColumn(
                          label: Text('Game'),
                        ),
                        DataColumn(
                          label: Text('Date'),
                        ),
                        DataColumn(
                          label: Text('Quantity'),
                        ),
                      ],
                      rows: List<DataRow>.generate(
                        plays.length,
                        (int index) => DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.08);
                              }
                              if (index.isEven) {
                                return Colors.grey.withOpacity(0.3);
                              }
                              return null;
                            }),
                            onSelectChanged: (selected) {
                              if (selected!) {
                                log('row-selected: ${plays[index].id}, playes = ${plays[index].players}');
                              }
                            },
                            cells: [
                              _buildDataCell(
                                  index,
                                  0,
                                  Text(plays[index].gameName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      )),
                                  MediaQuery.of(context).size.width * 0.35),
                              _buildDataCell(
                                  index,
                                  1,
                                  Text(
                                    plays[index].date,
                                    textAlign: TextAlign.left,
                                  ),
                                  MediaQuery.of(context).size.width * 0.25),
                              _buildDataCell(
                                  index,
                                  2,
                                  getPlayersColumn(plays[index]),
                                  MediaQuery.of(context).size.width * 0.4),
                            ]),
                      ),
                    )),
                SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: FittedBox(
                        child: DataTable(
                      columnSpacing: 20,
                      headingRowHeight: 0,
                      showCheckboxColumn: false,
                      columns: const <DataColumn>[
                        DataColumn(
                          label: Text('Game'),
                        ),
                        DataColumn(
                          label: Text('Quantity'),
                        ),
                      ],
                      rows: List<DataRow>.generate(
                        gamePlays.length,
                        (int index) => DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                            // All rows will have the same selected color.
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.08);
                            }
                            // Even rows will have a grey color.
                            if (index.isEven) {
                              return Colors.grey[300];
                            }
                            return null;
                          }),
                          onLongPress: () {
                            log("Long press");
                          },
                          onSelectChanged: (selected) {
                            if (selected!) {
                              log('row-selected: ${gamePlays[index].gameId}, playes = ${gamePlays[index].count}');
                            }
                          },
                          cells: <DataCell>[
                            DataCell(SizedBox(
                                width: MediaQuery.of(context).size.width * 0.75,
                                child: Text(
                                  gamePlays[index].gameName,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                ))),
                            DataCell(Text(
                              gamePlays[index].count.toString(),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            )),
                          ],
                        ),
                      ),
                    ))),
                SafeArea(
                  child: SfCartesianChart(
                    title: const ChartTitle(text: "Games stats"),
                    primaryXAxis: const CategoryAxis(
                      labelRotation: 270,
                      interval: 1,
                      majorGridLines: MajorGridLines(width: 0),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<_GamePlaysCount, String>>[
                      ColumnSeries(
                        dataSource: gamePlays,
                        dataLabelMapper: (_GamePlaysCount data, _) =>
                            data.gameNameShort,
                        xValueMapper: (_GamePlaysCount data, _) =>
                            data.gameNameShort,
                        yValueMapper: (_GamePlaysCount data, _) => data.count,
                      )
                    ],
                  ),
                ),
                SafeArea(
                  child: SfCircularChart(
                    title: const ChartTitle(text: "Games stats"),
                    margin: const EdgeInsets.all(0),
                    legend: const Legend(
                        isVisible: true, position: LegendPosition.bottom),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <PieSeries<_GamePlaysCount, String>>[
                      PieSeries(
                        explode: true,
                        dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelIntersectAction: LabelIntersectAction.shift,
                            labelPosition: ChartDataLabelPosition.outside,
                            useSeriesColor: true),
                        dataSource: gamePlays,
                        name: "Games",
                        dataLabelMapper: (_GamePlaysCount data, _) =>
                            data.gameName,
                        xValueMapper: (_GamePlaysCount data, _) =>
                            data.gameName,
                        yValueMapper: (_GamePlaysCount data, _) => data.count,
                      )
                    ],
                  ),
                ),
              ]),
            );
          })),
          SizedBox(
              child: Text(
            statsSummary,
            textAlign: TextAlign.center,
          )),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Slider(
                  value: firstGamesCount,
                  min: 0,
                  max: 25,
                  divisions: 26,
                  label: firstGamesCount.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      firstGamesCount = value;
                    });
                  },
                )),
            const Text(
              "Games limit",
              overflow: TextOverflow.ellipsis,
            )
          ]),
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.075,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        color: Colors.brown,
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: double.maxFinite,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (players.isEmpty) {
                              players = await getAllPlayers();
                            }
                            showDialog(
                                context: context,
                                builder: (buildContext) {
                                  return StatefulBuilder(
                                      builder: (context, setState) {
                                    return AlertDialog(
                                        content: Column(children: [
                                      const Text(
                                        "Games limit",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                              child: Slider(
                                            value: firstGamesCount,
                                            min: 0,
                                            max: 25,
                                            divisions: 26,
                                            label: firstGamesCount
                                                .round()
                                                .toString(),
                                            onChanged: (double value) {
                                              setState(() {
                                                firstGamesCount = value;
                                              });
                                            },
                                          )),
                                          const Text(
                                            "Players count",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                            child: RangeSlider(
                                              values: maxRangeValues,
                                              max: 10,
                                              divisions: 10,
                                              labels: RangeLabels(
                                                  maxRangeValues.start
                                                      .round()
                                                      .toString(),
                                                  maxRangeValues.end
                                                      .round()
                                                      .toString()),
                                              onChanged: (RangeValues values) {
                                                setState(() {
                                                  maxRangeValues = values;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            DropdownButton(
                                              value: chosenGames.isNotEmpty
                                                  ? chosenGames[chosenGameId]
                                                  : null,
                                              onChanged: (String? value) {
                                                chosenGameId = chosenGames
                                                    .entries
                                                    .firstWhere((entry) =>
                                                        entry.value == value)
                                                    .key;
                                                setState(() {});
                                              },
                                              items: chosenGames.values.map<
                                                      DropdownMenuItem<String>>(
                                                  (String value) {
                                                return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(value));
                                              }).toList(),
                                            ),
                                            ChoiceChip(
                                              label: const Text("Winrate"),
                                              selected: winRate,
                                              onSelected: (bool value) {
                                                setState(() {
                                                  winRate = value;
                                                });
                                              },
                                              shape:
                                                  const RoundedRectangleBorder(
                                                side: BorderSide(
                                                    color: Colors.black12),
                                                borderRadius: BorderRadius.zero,
                                              ),
                                            ),
                                            ChoiceChip(
                                              label: const Text(
                                                  "Only chosen players"),
                                              selected: onlyChosenPlayers,
                                              onSelected: (bool value) {
                                                setState(() {
                                                  onlyChosenPlayers = value;
                                                });
                                              },
                                              shape:
                                                  const RoundedRectangleBorder(
                                                side: BorderSide(
                                                    color: Colors.black12),
                                                borderRadius: BorderRadius.zero,
                                              ),
                                            ),
                                            ChoiceChip(
                                              label: const Text(
                                                  "Winner among chosen players"),
                                              selected:
                                                  winnerAmongChosenPlayers,
                                              onSelected: (bool value) {
                                                setState(() {
                                                  winnerAmongChosenPlayers =
                                                      value;
                                                });
                                              },
                                              shape:
                                                  const RoundedRectangleBorder(
                                                side: BorderSide(
                                                    color: Colors.black12),
                                                borderRadius: BorderRadius.zero,
                                              ),
                                            ),
                                          ]),
                                      const Text("Players"),
                                      Expanded(
                                          child: SingleChildScrollView(
                                              child: Column(
                                                  children:
                                                      players.map((player) {
                                        return CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                ChoiceChip(
                                                  label: const Text("exclude?"),
                                                  selected: player['excluded'],
                                                  onSelected: (bool? value) {
                                                    setState(() {
                                                      player['excluded'] =
                                                          value;
                                                    });
                                                  },
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    side: BorderSide(
                                                        color: Colors.black12),
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                    child: Text(
                                                  player['name'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ))
                                              ]),
                                          value: player['isChecked'],
                                          onChanged: (bool? value) {
                                            setState(() {
                                              player['isChecked'] = value;
                                            });
                                          },
                                        );
                                      }).toList())))
                                    ]));
                                  });
                                });
                          },
                          label: const Text("Filters"),
                          icon: const Icon(Icons.filter_alt),
                        )),
                    Container(
                        color: Colors.brown,
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: double.maxFinite,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Get last plays
                            if (needUpdatePlaysFromBgg) {
                              int maxPlayerId = await PlayersSQL.getMaxID();
                              int maxLocationId = await LocationSQL.getMaxID();
                              await getPlaysFromPage(
                                  1, maxPlayerId, maxLocationId);
                              needUpdatePlaysFromBgg = false;
                            }

                            List<BggPlay> allPlays = [];
                            plays.clear();
                            allPlays =
                                await PlaysSQL.getAllPlays(startDate, endDate);

                            var chosenPlayers = players
                                .where((element) => element['isChecked']);

                            var excludedPlayers =
                                players.where((element) => element['excluded']);

                            // Get plays with chosen players
                            if (chosenPlayers.isEmpty) {
                              plays = allPlays;
                            } else {
                              for (var allPlay in allPlays) {
                                if (allPlay.players == null) continue;

                                // Exclude players
                                var haveExcludedPlayer = false;
                                for (var excludedPlayer in excludedPlayers) {
                                  if (allPlay.players!
                                      .split(";")
                                      .join("|")
                                      .contains(excludedPlayer['name'])) {
                                    haveExcludedPlayer = true;
                                    break;
                                  }
                                }
                                if (haveExcludedPlayer) continue;

                                var chosenMatches = 0;
                                var winnerAmongThisPlay = false;
                                for (var chosenPlayer in chosenPlayers) {
                                  if (allPlay.players!
                                      .split(";")
                                      .join("|")
                                      .contains(chosenPlayer['name'])) {
                                    chosenMatches++;
                                  }
                                }

                                // Check winner among chosen players
                                for (var chosenPlayer in chosenPlayers) {
                                  if (allPlay.winners!
                                      .split(";")
                                      .contains(chosenPlayer['name'])) {
                                    winnerAmongThisPlay = true;
                                    break;
                                  }
                                }

                                if (onlyChosenPlayers) {
                                  if (chosenMatches ==
                                          allPlay.players!.split(";").length &&
                                      chosenMatches == chosenPlayers.length) {
                                    if (winnerAmongChosenPlayers &&
                                        !winnerAmongThisPlay) continue;
                                    plays.add(allPlay);
                                  }
                                } else {
                                  if (chosenMatches >= chosenPlayers.length) {
                                    if (winnerAmongChosenPlayers &&
                                        !winnerAmongThisPlay) continue;
                                    plays.add(allPlay);
                                  }
                                }
                              }
                            }

                            if (chosenGameId != 0) {
                              plays = plays
                                  .where((e) => e.gameId == chosenGameId)
                                  .toList();
                            }

                            plays = plays
                                .where((e) =>
                                    e.players!.split(';').length <=
                                        maxRangeValues.end &&
                                    e.players!.split(';').length >=
                                        maxRangeValues.start)
                                .toList();
                            plays.sort((a, b) => b.id.compareTo(a.id));
                            // Get all plays and plays count for each game
                            gamePlays.clear();
                            List<_GamePlaysCount> allGames = [];
                            List<_GamePlaysCount> allWinners = [];
                            var allPlayers = (await PlayersSQL.getAllPlayers());
                            if (!winRate) {
                              for (var play in plays) {
                                if (allGames
                                    .map((e) => e.gameName)
                                    .contains(play.gameName)) {
                                  var gamePlay = allGames
                                      .where((element) =>
                                          element.gameName == play.gameName)
                                      .first;
                                  gamePlay.count =
                                      gamePlay.count! + play.quantity!;
                                } else {
                                  allGames.add(_GamePlaysCount(
                                      play.gameName,
                                      play.gameName,
                                      play.quantity,
                                      play.gameId));
                                }
                              }
                              // Winrate
                            } else {
                              for (var play in plays) {
                                if (play.winners != null &&
                                    play.winners!.isNotEmpty) {
                                  var winners = play.winners!.split(';');

                                  for (var winner in winners) {
                                    if (winner == '0') {
                                      continue;
                                    }
                                    if (allWinners
                                        .map((e) => e.gameName)
                                        .contains(winner)) {
                                      var existingWinner = allWinners
                                          .where((element) =>
                                              element.gameName == winner)
                                          .first;
                                      existingWinner.count =
                                          existingWinner.count! + 1;
                                    } else {
                                      var winnerFromDb = allPlayers
                                          .where((e) => e['name'] == (winner));
                                      if (winnerFromDb.isEmpty) {
                                        continue;
                                      }

                                      allWinners.add(_GamePlaysCount(winner,
                                          winner, 1, winnerFromDb.first['id']));
                                    }
                                  }
                                }
                              }
                            }

                            if (winRate) {
                              allGames = allWinners;
                            }

                            for (var e in allGames) {
                              e.gameNameShort.length > 20
                                  ? e.gameNameShort =
                                      "${e.gameNameShort.substring(0, 18)}..."
                                  : e.gameNameShort;
                            }
                            allGames
                                .sort((a, b) => b.count!.compareTo(a.count!));
                            if (firstGamesCount != 0) {
                              gamePlays = allGames
                                  .take(firstGamesCount.round())
                                  .toList();
                            } else {
                              gamePlays = allGames;
                            }

                            setState(() {
                              statsSummary =
                                  "Total plays: ${allGames.fold(0, (sum, item) => sum + item.count!)} total games: ${allGames.length}";
                            });
                          },
                          style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                  Theme.of(context).colorScheme.secondary)),
                          label: const Text("Get plays"),
                          icon: const Icon(Icons.leaderboard),
                        )),
                    Container(
                        color: Colors.brown,
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: double.maxFinite,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            plays = await getNewPlays();
                            setState(() {});
                          },
                          label: const Text(
                            "First plays",
                            textAlign: TextAlign.center,
                          ),
                        )),
                    Container(
                        color: Colors.brown,
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: double.maxFinite,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            exportCSV();
                          },
                          label: const Text("Export table",
                              textAlign: TextAlign.center),
                        ))
                  ])),
          Flexible(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    color: Colors.tealAccent,
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: double.maxFinite,
                    child: ElevatedButton(
                        onPressed: () async {
                          var pickedDate = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(3000));
                          if (pickedDate != null) {
                            setState(() {
                              startDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          "Period start ${dateFormat.format(startDate!)}",
                          textAlign: TextAlign.center,
                        )),
                  ),
                  Container(
                      color: Colors.tealAccent,
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: ElevatedButton(
                                  child: const Text("This year"),
                                  onPressed: () {
                                    setState(() {
                                      startDate = DateTime(DateTime.now().year);
                                      endDate = DateTime.now();
                                    });
                                  })),
                          Expanded(
                              child: ElevatedButton(
                            child: const Text("Last year"),
                            onPressed: () {
                              setState(() {
                                startDate = DateTime(DateTime.now()
                                    .add(const Duration(days: -365))
                                    .year);
                                endDate = DateTime(
                                    DateTime.now()
                                        .add(const Duration(days: -365))
                                        .year,
                                    12,
                                    31);
                              });
                            },
                          ))
                        ],
                      )),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: double.maxFinite,
                    child: ElevatedButton(
                        onPressed: () async {
                          var pickedDate = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(3000));
                          if (pickedDate != null) {
                            setState(() {
                              endDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          "Period end ${dateFormat.format(endDate!)}",
                          textAlign: TextAlign.center,
                        )),
                  )
                ],
              )),
        ],
      ),
    )));
  }

  Future<List<BggPlay>> getNewPlays() async {
    List<BggPlay> chosenPeriodPlays = [];
    chosenPeriodPlays = await PlaysSQL.getAllPlays(startDate, endDate);
    chosenPeriodPlays.sort((a, b) => a.id.compareTo(b.id));
    Set<int> firstPlaysGameIds = {};
    List<BggPlay> firstPlays = [];

    for (var play in chosenPeriodPlays) {
      if (firstPlaysGameIds.add(play.gameId)) {
        firstPlays.add(play);
      }
    }

    List<BggPlay> oldPlays = [];
    oldPlays = await PlaysSQL.getAllPlays(DateTime(2000), startDate);

    List<BggPlay> newPlays = firstPlays
        .where((element) =>
            !oldPlays.map((e) => e.gameId).contains(element.gameId))
        .toList();

    return (newPlays);
  }

  void exportCSV() async {
    String csv =
        "id,date,gameId,gameName,quantity,location,players,winners,comments,duration\n";

    for (var play in plays) {
      csv +=
          "${play.id},${play.date},${play.gameId},${play.gameName},${play.quantity},${play.location},${play.players},${play.winners},${play.comments},${play.duration}\n"; // Добавьте данные
    }

    Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      throw Exception("Unsupported platform");
    }
    String baseFileName =
        "bggSparrow_stats_${dateFormat.format(startDate!)}_${dateFormat.format(endDate!)}";
    String fileExtension = ".csv";

    int fileIndex = 1;
    String fileName = "$baseFileName($fileIndex)$fileExtension";
    String path = "${directory.path}/$fileName";

    // Проверяем, существует ли файл, и увеличиваем номер, если это так
    while (await File(path).exists()) {
      fileIndex++;
      fileName = "$baseFileName($fileIndex)$fileExtension";
      path = "${directory.path}/$fileName";
    }

    File file = File(path);
    await file.writeAsString(csv);

    // Разделение строки по символу '/'
    List<String> parts = directory.path.split('/');
    if (parts.isNotEmpty && parts.last.isEmpty) {
      parts.removeLast();
    }
    final folderName = parts.last;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        action: SnackBarAction(
          label: 'Open file',
          onPressed: () async {
            final filePath = path;
            await OpenFile.open(filePath);
          },
        ),
        content: Text("Table was exported to: '$folderName'")));
  }
}

Column getPlayersColumn(BggPlay bggPlay) {
  var players = bggPlay.players;
  if (players == null || players.isEmpty) {
    return const Column(children: []);
  } else {
    List<Widget> columnChildren = [];
    for (var playerInfo in players.split(';')) {
      var playerName = playerInfo.split('|').last;
      if (bggPlay.winners != null && bggPlay.winners!.contains(playerName)) {
        columnChildren.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber),
            Text(
              playerName.length > maxColumnPlayerNameLength
                  ? "${playerName.substring(0, maxColumnPlayerNameLength)}..."
                  : playerName,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ));
      } else {
        columnChildren
            .add(Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
              playerName.length > maxColumnPlayerNameLength
                  ? "${playerName.substring(0, maxColumnPlayerNameLength)}..."
                  : playerName,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis)
        ]));
      }
    }
    return Column(
      children: columnChildren,
    );
  }
}

class _GamePlaysCount {
  _GamePlaysCount(this.gameName, this.gameNameShort, this.count, this.gameId);

  String gameName;
  String gameNameShort;
  int? count;
  int gameId;
}

// void _showContextMenu(
//   BuildContext context,
//   Offset position,
//   int rowId,
// ) {
//   final RelativeRect menuPosition = RelativeRect.fromLTRB(
//     position.dx,
//     position.dy,
//     position.dx,
//     position.dy,
//   );

//   showMenu<String>(
//     context: context,
//     position: menuPosition,
//     items: const [
//       PopupMenuItem(value: 'delete', child: Text('Удалить')),
//       PopupMenuItem(value: 'edit', child: Text('Редактировать')),
//     ],
//   ).then((value) {
//     if (value == 'delete') {
//       //_deleteRow(rowId);
//     } else if (value == 'edit') {
//       //_editRow(rowId);
//     }
//   });
// }

class _MeasuredCell extends StatefulWidget {
  final Widget content;
  final int rowIndex;
  final Function(int, double) onHeightMeasured;
  final double? maxHeight;

  const _MeasuredCell({
    required this.content,
    required this.rowIndex,
    required this.onHeightMeasured,
    this.maxHeight,
  });

  @override
  __MeasuredCellState createState() => __MeasuredCellState();
}

class __MeasuredCellState extends State<_MeasuredCell> {
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  void _measureHeight() {
    final renderBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final height = renderBox.size.height;
      widget.onHeightMeasured(widget.rowIndex, height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _contentKey,
      height: widget.maxHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: widget.content,
      ),
    );
  }
}
