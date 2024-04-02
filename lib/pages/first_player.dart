import 'package:flutter/material.dart';
import '../touch_indicator.dart';

class FirstPlayerChoser extends StatefulWidget {
  const FirstPlayerChoser({super.key});

  @override
  State<FirstPlayerChoser> createState() => _FirstPlayerChoserState();
}

class _FirstPlayerChoserState extends State<FirstPlayerChoser> {
  @override
  Widget build(BuildContext context) {
    return TouchIndicator(
        forceInReleaseMode: true,
        enabled: true,
        indicatorSize: 120,
        indicatorColor: const Color.fromARGB(255, 32, 184, 19),
        child: Scaffold(
          appBar: AppBar(title: const Text("Touch")),
          body: const Text(
            "Chose first player",
            textAlign: TextAlign.center,
          ),
        ));
  }
}
