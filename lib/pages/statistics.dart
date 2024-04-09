import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/plays_sql.dart';
import '../models/bgg_play_model.dart';
import '../db/game_things_sql.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  List<BggPlay> plays = [];
  DateTime? startDate = DateTime(2000);
  DateTime? endDate = DateTime(3000);
  var dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Statistics"),
          centerTitle: true,
        ),
        body: SafeArea(
            child: DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                  child: const TabBar(tabs: [
                Tab(text: "Table"),
                Tab(text: "Histogram"),
                Tab(text: "Piechart"),
              ])),
              LayoutBuilder(builder: ((context, constraints) {
                return Container(
                  //Add this to give height
                  height: MediaQuery.of(context).size.height * 0.50,
                  child: TabBarView(children: [
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
                                  label: Text('Date'),
                                ),
                                DataColumn(
                                  label: Text('Quantity'),
                                ),
                              ],
                              rows: List<DataRow>.generate(
                                plays.length,
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
                                  onSelectChanged: (selected) {
                                    if (selected!) {
                                      print(
                                          'row-selected: ${plays[index].id}, playes = ${plays[index].players}');
                                    }
                                  },
                                  cells: <DataCell>[
                                    DataCell(
                                      SizedBox(
                                          width: constraints.maxWidth * 0.2,
                                          child: Text(plays[index].gameName)),
                                    ),
                                    DataCell(SizedBox(
                                        width: constraints.maxWidth * 0.2,
                                        child: Text(plays[index].date))),
                                    DataCell(SizedBox(
                                        width: constraints.maxWidth * 0.2,
                                        child: Text(
                                          plays[index].players != null
                                              ? plays[index]
                                                  .players!
                                                  .split(';')
                                                  .map((e) => e.split('|').last)
                                                  .join('\n')
                                                  .toString()
                                              : "",
                                          overflow: TextOverflow.ellipsis,
                                        ))),
                                  ],
                                ),
                              ),
                            ))),
                    Text("Articles Body"),
                    Text("User Body"),
                  ]),
                );
              })),
              Flexible(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () async {
                      plays = await PlaysSQL.getAllPlays(startDate, endDate);
                      setState(() {});
                    },
                    child: const Text("Get plays"),
                  )),
              Flexible(
                  flex: 1,
                  child: Row(
                    children: [
                      Column(
                        children: [
                          ElevatedButton(
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
                              child: Text("Choose period start")),
                          Text(dateFormat.format(startDate!))
                        ],
                      ),
                      Column(
                        children: [
                          ElevatedButton(
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
                              child: Text("Choose period end")),
                          Text(dateFormat.format(endDate!))
                        ],
                      )
                    ],
                  )),
              Flexible(
                  flex: 1,
                  child: ElevatedButton(
                    child: Text("This year"),
                    onPressed: () {
                      setState(() {
                        startDate = DateTime(DateTime.now().year);
                        endDate = DateTime.now();
                      });
                    },
                  ))
            ],
          ),
        )));
  }
}
