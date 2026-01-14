import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../s.dart';

class PlayDatePicker extends StatefulWidget {
  static final PlayDatePicker _singleton = PlayDatePicker._internal();

  factory PlayDatePicker() {
    return _singleton;
  }

  PlayDatePicker._internal();
  var playDate = DateTime.now();

  @override
  State<PlayDatePicker> createState() => _PlayDatePickerState();
}

class _PlayDatePickerState extends State<PlayDatePicker> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          var pickedDate = await showDatePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(3000));
          if (pickedDate != null) {
            setState(() {
              widget.playDate = pickedDate;
            });
          }
        },
        label: Text(
            "${S.of(context).playDate}: ${DateFormat('yyyy-MM-dd').format(widget.playDate)}"),
        icon: const Icon(Icons.calendar_today));
  }
}

class PlayDatePickerSimple extends StatefulWidget {
  PlayDatePickerSimple({required this.date, super.key});
  String date;

  @override
  State<PlayDatePickerSimple> createState() => _PlayDatePickerSimpleState();
}

class _PlayDatePickerSimpleState extends State<PlayDatePickerSimple> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          var pickedDate = await showDatePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(3000));
          if (pickedDate != null) {
            setState(() {
              widget.date = DateFormat('yyyy-MM-dd').format(pickedDate);
            });
          }
        },
        label: Text(
            "${S.of(context).playDate}: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.date))}"),
        icon: const Icon(Icons.calendar_today));
  }
}
