import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:intl/intl.dart';
import '../db/plays_sql.dart';
import '../models/bgg_play_model.dart';
import '../db/game_things_sql.dart';

// Free licence for small companies <5 developers and 1 millions $
import 'package:syncfusion_flutter_charts/charts.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  double firstGamesCount = 10;
  List<BggPlay> plays = [];
  Map<int, int> gameThingPlays = {};
  DateTime? startDate = DateTime(2000);
  DateTime? endDate = DateTime(3000);
  var dateFormat = DateFormat('yyyy-MM-dd');
  List<_GamePlaysCount> gamePlays = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Statistics"),
          centerTitle: true,
        ),
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
                    SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
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
                                DataCell(
                                  Text(plays[index].gameName),
                                ),
                                DataCell(Text(plays[index].date)),
                                DataCell(Text(
                                  plays[index].players != null
                                      ? plays[index]
                                          .players!
                                          .split(';')
                                          .map((e) => e.split('|').last)
                                          .join('\n')
                                          .toString()
                                      : "",
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ],
                            ),
                          ),
                        )),
                    Container(
                        child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              headingRowHeight: 0,
                              showCheckboxColumn: false,
                              dataRowMaxHeight: double.infinity,
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
                                  color:
                                      MaterialStateProperty.resolveWith<Color?>(
                                          (Set<MaterialState> states) {
                                    // All rows will have the same selected color.
                                    if (states
                                        .contains(MaterialState.selected)) {
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
                                    DataCell(
                                      Text(gamePlays[index].gameName),
                                    ),
                                    DataCell(Text(
                                      gamePlays[index].count.toString(),
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                  ],
                                ),
                              ),
                            ))),
                    SafeArea(
                      child: SfCartesianChart(
                        title: ChartTitle(text: "Games stats"),

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
                                data.gameName,
                            xValueMapper: (_GamePlaysCount data, _) =>
                                data.gameName,
                            yValueMapper: (_GamePlaysCount data, _) =>
                                data.count,
                          )
                        ],
                      ),
                    ),
                    SafeArea(
                      child: SfCircularChart(
                        title: ChartTitle(text: "Games stats"),
                        margin: EdgeInsets.all(0),
                        legend: Legend(
                            isVisible: true, position: LegendPosition.bottom),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <PieSeries<_GamePlaysCount, String>>[
                          PieSeries(
                            explode: true,
                            dataLabelSettings: DataLabelSettings(
                                isVisible: true,
                                labelIntersectAction:
                                    LabelIntersectAction.shift,
                                labelPosition: ChartDataLabelPosition.outside,
                                useSeriesColor: true),
                            dataSource: gamePlays,
                            name: "Games",
                            dataLabelMapper: (_GamePlaysCount data, _) =>
                                data.gameName,
                            xValueMapper: (_GamePlaysCount data, _) =>
                                data.gameName,
                            yValueMapper: (_GamePlaysCount data, _) =>
                                data.count,
                          )
                        ],
                      ),
                    ),
                  ]),
                );
              })),
              SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.05,
                  child: Row(children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.66,
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
                      "Top N games",
                      overflow: TextOverflow.ellipsis,
                    )
                  ])),
              Container(
                  color: Colors.brown,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.075,
                  child: ElevatedButton(
                    onPressed: () async {
                      plays = await PlaysSQL.getAllPlays(startDate, endDate);

                      gamePlays.clear();
                      List<_GamePlaysCount> allGames = [];
                      for (var play in plays) {
                        if (allGames
                            .map((e) => e.gameName)
                            .contains(play.gameName)) {
                          var gamePlay = allGames
                              .where((element) =>
                                  element.gameName == play.gameName)
                              .first;
                          gamePlay.count = gamePlay.count! + play.quantity!;
                        } else {
                          allGames.add(_GamePlaysCount(
                              play.gameName, play.quantity, play.gameId));
                        }
                      }
                      allGames.forEach((e) => e.gameName.length > 20
                          ? e.gameName = "${e.gameName.substring(0, 18)}..."
                          : e.gameName);
                      allGames.sort((a, b) => b.count!.compareTo(a.count!));
                      if (firstGamesCount != 0) {
                        gamePlays =
                            allGames.take(firstGamesCount.round()).toList();
                      } else {
                        gamePlays = allGames;
                      }

                      setState(() {});
                    },
                    child: const Text("Get plays"),
                  )),
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
                                      child: Text("This year"),
                                      onPressed: () {
                                        setState(() {
                                          startDate =
                                              DateTime(DateTime.now().year);
                                          endDate = DateTime.now();
                                        });
                                      })),
                              Expanded(
                                  child: ElevatedButton(
                                child: Text("Last year"),
                                onPressed: () {
                                  setState(() {
                                    startDate = DateTime(DateTime.now()
                                        .add(Duration(days: -365))
                                        .year);
                                    endDate = DateTime(
                                        DateTime.now()
                                            .add(Duration(days: -365))
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

class _GamePlaysCount {
  _GamePlaysCount(this.gameName, this.count, this.gameId);

  String gameName;
  int? count;
  int gameId;
}
