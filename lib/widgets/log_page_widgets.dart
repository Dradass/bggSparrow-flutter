import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlexButton extends StatelessWidget {
  Widget childWidget;

  @override
  Widget build(BuildContext context) {
    return Flexible(
        flex: 3,
        child: SizedBox(
            //color: Colors.tealAccent,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: childWidget));
  }

  FlexButton(this.childWidget, {super.key});
}

class PlayDatePicker extends StatefulWidget {
  static final PlayDatePicker _singleton = PlayDatePicker._internal();

  factory PlayDatePicker() {
    return _singleton;
  }

  PlayDatePicker._internal();
  DateTime playDate = DateTime.now();

  @override
  State<PlayDatePicker> createState() => _PlayDatePickerState();

  //PlayDatePicker(this.playDate, {super.key});
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
            "Playdate: ${DateFormat('yyyy-MM-dd').format(widget.playDate)}"),
        icon: const Icon(Icons.calendar_today));
  }
}
