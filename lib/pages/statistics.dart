import 'package:flutter/material.dart';
import '../db/plays_sql.dart';
import '../models/bgg_play_model.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  static const int numItems = 20;
  List<BggPlay> plays = [];

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
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () async {
                      plays = await PlaysSQL.getAllPlays();
                      print("all plays count = ${plays.length}");
                      setState(() {});
                    },
                    child: const Text("Get plays"),
                  )),
              Flexible(
                  //height: MediaQuery.of(context).size.height,
                  flex: 1,
                  child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: const <DataColumn>[
                          DataColumn(
                            label: Text('ID'),
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
                                Text(plays[index].id.toString()),
                              ),
                              DataCell(Text(plays[index].date.toString())),
                              DataCell(Text(plays[index].quantity.toString()))
                            ],
                          ),
                        ),
                      )))
            ],
          )
        ])));
  }
}
