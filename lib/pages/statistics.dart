
import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/players_sql.dart';
import 'package:intl/intl.dart';
import '../db/plays_sql.dart';
import '../models/bgg_play_model.dart';
import '../bggApi/bggApi.dart';

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
  bool winRate = false;
  bool onlyChosenPlayers = false;
  bool winnerAmongChosenPlayers = false;
  RangeValues maxRangeValues = const RangeValues(0, 10);
  List<Map> players = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: DefaultTabController(
      length: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
              child: const TabBar(tabs: [
            Tab(text: "Plays"),
            Tab(text: "Table"),
            Tab(text: "Histogram"),
            Tab(text: "Piechart"),
          ])),
          LayoutBuilder(builder: ((context, constraints) {
            return SizedBox(
              //Add this to give height
              height: MediaQuery.of(context).size.height * 0.50,
              child: TabBarView(children: [
                // StatsTable(plays),
                SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      headingRowHeight: 0,
                      columnSpacing: 20,
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
                          color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                            // All rows will have the same selected color.
                            if (states.contains(MaterialState.selected)) {
                              return Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.08);
                            }
                            // Even rows will have a grey color.
                            if (index.isEven) {
                              return Colors.grey.withOpacity(0.3);
                            }
                            return null; // Use default value for other states and odd rows.
                          }),
                          onSelectChanged: (selected) {
                            if (selected!) {
                              print(
                                  'row-selected: ${plays[index].id}, playes = ${plays[index].players}');
                            }
                          },
                          cells: <DataCell>[
                            DataCell(SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: Text(plays[index].gameName),
                            )),
                            DataCell(Text(
                              plays[index].date,
                              textAlign: TextAlign.left,
                            )),
                            DataCell(getPlayersColumn(plays[index])),
                          ],
                        ),
                      ),
                    )),
                Container(
                    child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: FittedBox(
                            child:
                                //StatsTable(),
                                DataTable(
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
                              color: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                // All rows will have the same selected color.
                                if (states.contains(MaterialState.selected)) {
                                  return Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.08);
                                }
                                // Even rows will have a grey color.
                                if (index.isEven) {
                                  return Colors.grey.withOpacity(0.3);
                                }
                                return null; // Use default value for other states and odd rows.
                              }),
                              onLongPress: () {
                                print("Long press");
                              },
                              onSelectChanged: (selected) {
                                if (selected!) {
                                  print(
                                      'row-selected: ${gamePlays[index].gameId}, playes = ${gamePlays[index].count}');
                                }
                              },
                              cells: <DataCell>[
                                DataCell(SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.75,
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
                        )))),
                SafeArea(
                  child: SfCartesianChart(
                    title: const ChartTitle(text: "Games stats"),

                    primaryXAxis: const CategoryAxis(
                      labelRotation: 270,
                      // labelIntersectAction:
                      //     AxisLabelIntersectAction.multipleRows,
                      interval: 1,
                      majorGridLines: MajorGridLines(width: 0),
                    ),
                    // primaryYAxis: const NumericAxis(
                    //     axisLine: AxisLine(width: 0),
                    //     labelFormat: '{value}%',
                    //     majorTickLines: MajorTickLines(size: 0)),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<_GamePlaysCount, String>>[
                      ColumnSeries(
                        dataSource: gamePlays,
                        // name: "Games",
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
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: double.maxFinite,
                        child: ElevatedButton.icon(
                          onPressed: () async {
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

                            plays = plays
                                .where((e) =>
                                    e.players!.split(';').length <=
                                        maxRangeValues.end &&
                                    e.players!.split(';').length >=
                                        maxRangeValues.start)
                                .toList();

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
                          label: const Text("Get plays"),
                          icon: const Icon(Icons.leaderboard),
                        )),
                    Container(
                        color: Colors.brown,
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: double.maxFinite,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (players.isEmpty) {
                              players = await getLocalPlayers();
                            }
                            showDialog(
                                context: context,
                                builder: (BuildContext) {
                                  return StatefulBuilder(
                                      builder: (context, setState) {
                                    return AlertDialog(
                                        //insetPadding: EdgeInsets.zero,
                                        //title: const Text("Your friends"),
                                        content: Column(children: [
                                      const Text(
                                        "Games limit",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Container(
                                          child: Column(
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
                                      )),
                                      Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ChoiceChip(
                                              label: const Text("Winrate"),
                                              selected: winRate,
                                              onSelected: (bool value) {
                                                setState(() {
                                                  winRate = value;
                                                });
                                              },
                                              shape: const RoundedRectangleBorder(
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
                                              shape: const RoundedRectangleBorder(
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
                                              shape: const RoundedRectangleBorder(
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
                                                  shape: const RoundedRectangleBorder(
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
                        ))
                  ])),
          Flexible(
              flex: 1,
              // color: Colors.amberAccent,
              // width: MediaQuery.of(context).size.width,
              //height: MediaQuery.of(context).size.height * 0.125,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    color: Colors.tealAccent,
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: double.maxFinite,
                    //height: MediaQuery.of(context).size.height * 0.125,
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
}

Column getPlayersColumn(BggPlay bggPlay) {
  var players = bggPlay.players;
  if (players == null || players.isEmpty) {
    return const Column(children: []);
  } else {
    List<Widget> columnChildren = [];
    for (var playerInfo in players.split(';')) {
      var playerName = limitName(playerInfo.split('|').last, 9);
      if (bggPlay.winners != null && bggPlay.winners!.contains(playerName)) {
        columnChildren.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber),
            Text(
              playerName,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ));
      } else {
        columnChildren.add(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(playerName,
                  textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)
            ]));
      }
    }
    return Column(
      children: columnChildren,
    );
  }
}

String limitName(String name, int limit) {
  if (name.length <= limit) {
    return name;
  } else {
    return "${name.substring(0, limit)}...";
  }
}

class _GamePlaysCount {
  _GamePlaysCount(this.gameName, this.gameNameShort, this.count, this.gameId);

  String gameName;
  String gameNameShort;
  int? count;
  int gameId;
}
