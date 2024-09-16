import 'package:flutter/material.dart';
import '../../models/bgg_play_model.dart';

class StatsTable extends StatefulWidget {
  static StatsTable? _singleton;

  factory StatsTable(List<BggPlay> plays) {
    _singleton ??= StatsTable._internal(plays);
    return _singleton!;
  }

  StatsTable._internal(this.plays);

  List<BggPlay> plays;

  @override
  State<StatsTable> createState() => _StatsTableState();
}

class _StatsTableState extends State<StatsTable> {
  @override
  Widget build(BuildContext context) {
    print(widget.plays.length);
    return SingleChildScrollView(
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
            widget.plays.length,
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
                      'row-selected: ${widget.plays[index].id}, playes = ${widget.plays[index].players}');
                }
              },
              cells: <DataCell>[
                DataCell(
                  Text(widget.plays[index].gameName),
                ),
                DataCell(Text(widget.plays[index].date)),
                DataCell(Text(
                  widget.plays[index].players != null
                      ? widget.plays[index].players!
                          .split(';')
                          .map((e) =>
                              e.split('|').last +
                              (widget.plays[index].winners != null &&
                                      widget.plays[index].winners!
                                          .split(";")
                                          .contains(e.split('|').last)
                                  ? ' (win)'
                                  : ''))
                          .join('\n')
                          .toString()
                      : "",
                  overflow: TextOverflow.ellipsis,
                )),
              ],
            ),
          ),
        ));
  }
}
