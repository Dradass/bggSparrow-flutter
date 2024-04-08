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
  static const int numItems = 20;
  List<BggPlay> plays = [];
  Map gameNames = {};
  DateTime? startDate = DateTime(2000);
  DateTime? endDate = DateTime(3000);
  var dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Game helper"),
          centerTitle: true,
        ),
        body: SafeArea(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(
            children: [
              Flexible(
                  //height: MediaQuery.of(context).size.height,
                  flex: 2,
                  child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
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
                            cells: <DataCell>[
                              DataCell(
                                Text(plays[index].gameName),
                              ),
                              DataCell(Text(plays[index].date)),
                              DataCell(Text(plays[index].quantity.toString()))
                            ],
                          ),
                        ),
                      ))),
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
          )
        ])));
  }
}
