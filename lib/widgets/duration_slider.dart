import 'package:flutter/material.dart';
import '../s.dart';

class DurationSliderWidget extends StatefulWidget {
  static final DurationSliderWidget _singleton =
      DurationSliderWidget._internal();

  factory DurationSliderWidget() {
    return _singleton;
  }

  DurationSliderWidget._internal();

  double durationCurrentValue = 60;

  @override
  State<DurationSliderWidget> createState() => _DurationSliderWidgetState();
}

class _DurationSliderWidgetState extends State<DurationSliderWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Slider(
          value: widget.durationCurrentValue,
          max: 500,
          divisions: 50,
          label: widget.durationCurrentValue.round().toString(),
          onChanged: (double value) {
            setState(() {
              widget.durationCurrentValue = value;
            });
          },
        ),
        Text(
          S.of(context).duration,
        )
      ],
    );
  }
}

class DurationSliderSimple extends StatefulWidget {
  DurationSliderSimple({required this.durationCurrentValue, super.key});
  double durationCurrentValue;

  @override
  State<DurationSliderSimple> createState() => _DurationSliderSimpleState();
}

class _DurationSliderSimpleState extends State<DurationSliderSimple> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Slider(
          value: widget.durationCurrentValue,
          max: 500,
          divisions: 50,
          label: widget.durationCurrentValue.round().toString(),
          onChanged: (double value) {
            setState(() {
              widget.durationCurrentValue = value;
            });
          },
        ),
        Text(
          "${S.of(context).duration}: ${widget.durationCurrentValue.round()}",
        )
      ],
    );
  }
}
