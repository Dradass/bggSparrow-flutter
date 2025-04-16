import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class FirstPlayerChoser extends StatefulWidget {
  const FirstPlayerChoser({super.key});

  @override
  State<FirstPlayerChoser> createState() => _FirstPlayerChoserState();
}

class _FirstPlayerChoserState extends State<FirstPlayerChoser> {
  Map<int, Offset> touchPositions = <int, Offset>{};
  List<Widget> children = [];
  int? randomPlayer;
  var indicator;
  bool forceInReleaseMode = true;
  bool enabled = true;
  var counter = "Touch the screen";
  double indicatorSize = 150;
  var indicatorColor = const Color.fromARGB(255, 32, 184, 19);
  final List<Color> colors = <Color>[
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.black
  ];
  double opacity = 1.0; // Добавлена переменная для управления прозрачностью

  Iterable<Widget> buildTouchIndicators() sync* {
    if (touchPositions.isNotEmpty) {
      for (var entry in touchPositions.entries) {
        final index = entry.key;
        final touchPosition = entry.value;
        final isRandomPlayer = index == randomPlayer;
        yield Positioned.directional(
          start: touchPosition.dx - indicatorSize / 2,
          top: touchPosition.dy - indicatorSize / 2,
          textDirection: TextDirection.ltr,
          child: AnimatedOpacity(
            opacity:
                isRandomPlayer ? 1.0 : opacity, // Использование AnimatedOpacity
            duration: const Duration(seconds: 1),
            child: indicator != null
                ? indicator!
                : Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      //color: colors[1], // indicatorColor.withOpacity(0.3),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: indicatorSize,
                      color: colors[Random()
                          .nextInt(5)], // indicatorColor.withOpacity(0.9),
                    ),
                  ),
          ),
        );
      }
    }
  }

  void savePointerPosition(int index, Offset position) {
    setState(() {
      touchPositions[index] = position;
    });
  }

  void clearPointerPosition(int index) {
    setState(() {
      touchPositions.remove(index);
      opacity = 1.0;
      counter = "Touch the screen";
    });
  }

  @override
  Widget build(BuildContext context) {
    var child = Scaffold(
      // appBar: AppBar(title: const Text("Touch the screen")),
      body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: FittedBox(
              child: Text(
            selectionColor: Colors.tealAccent,
            counter,
            textAlign: TextAlign.center,
          ))),
    );

    if ((kReleaseMode && !forceInReleaseMode) || !enabled) {
      return child;
    }

    children = [
      child,
      ...buildTouchIndicators(),
    ];

    return Listener(
      onPointerDown: (opm) {
        savePointerPosition(opm.pointer, opm.position);
        checkTouchPositions(touchPositions.length);
      },
      onPointerCancel: (opc) {
        clearPointerPosition(opc.pointer);
      },
      onPointerUp: (opc) {
        clearPointerPosition(opc.pointer);
      },
      child: Stack(children: children),
    );
  }

  void checkTouchPositions(int firstPositionsCount) async {
    if (touchPositions.length == firstPositionsCount &&
        touchPositions.length > 1) {
      setState(() {
        counter = "3";
      });
    }
    await Future.delayed(const Duration(seconds: 1));
    if (touchPositions.length == firstPositionsCount) {
      if (touchPositions.length > 1) {
        setState(() {
          counter = "2";
        });
      } else {
        setState(() {
          //opacity = 0.0;
          counter = "Waiting your friends";
        });
      }
    } else {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
    if (touchPositions.length == firstPositionsCount &&
        touchPositions.length > 1) {
      setState(() {
        counter = "1";
      });
    } else {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
    if (touchPositions.length == firstPositionsCount) {
      if (touchPositions.length > 1) {
        randomPlayer = ((touchPositions.keys).toList()..shuffle()).first;
        // for (var position in (touchPositions.keys).toList()..shuffle()) {
        //   if (position != randomPlayer) {
        //     touchPositions[position] = const Offset(-100, -100);
        //     savePointerPosition(position, touchPositions[position]!);
        //   }
        // }
        setState(() {
          counter = "";
          opacity = 0.0;
        });
      }
    } else {
      return;
    }
  }
}
