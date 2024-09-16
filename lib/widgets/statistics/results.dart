import 'package:flutter/material.dart';

class _GamePlaysCount {
  _GamePlaysCount(this.gameName, this.count, this.gameId);

  String gameName;
  int? count;
  int gameId;
}

class StatsTable extends StatefulWidget {
  static final StatsTable _singleton = StatsTable._internal();

  factory StatsTable() {
    return _singleton;
  }

  StatsTable._internal();

  List<_GamePlaysCount> gamePlays = [];

  @override
  State<StatsTable> createState() => _StatsTableState();
}

class _StatsTableState extends State<StatsTable> {
  @override
  Widget build(BuildContext context) {
    return DataTable(
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
        widget.gamePlays.length,
        (int index) => DataRow(
          color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            // All rows will have the same selected color.
            if (states.contains(MaterialState.selected)) {
              return Theme.of(context).colorScheme.primary.withOpacity(0.08);
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
                  'row-selected: ${widget.gamePlays[index].gameId}, playes = ${widget.gamePlays[index].count}');
            }
          },
          cells: <DataCell>[
            DataCell(
              Text(widget.gamePlays[index].gameName),
            ),
            DataCell(Text(
              widget.gamePlays[index].count.toString(),
              overflow: TextOverflow.ellipsis,
            )),
          ],
        ),
      ),
    );
  }
}
