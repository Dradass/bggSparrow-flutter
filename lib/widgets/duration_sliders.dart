import 'package:flutter/material.dart';

class DurationSlider extends StatefulWidget {
  const DurationSlider({super.key});

  @override
  State<DurationSlider> createState() => _DurationSliderState();
}

class _DurationSliderState extends State<DurationSlider> {
  double currentValue = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slider')),
      body: Slider(
        value: currentValue,
        max: 500,
        divisions: 50,
        label: currentValue.round().toString(),
        onChanged: (double value) {
          setState(() {
            currentValue = value;
          });
        },
      ),
    );
  }
}
