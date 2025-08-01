import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/system_parameters.dart';
import '../db/system_table.dart';
import 'dart:developer' as developer;
import '../globals.dart';
import '../s.dart';

class FirstPlayerChoser extends StatefulWidget {
  const FirstPlayerChoser({super.key});

  @override
  State<FirstPlayerChoser> createState() => _FirstPlayerChoserState();
}

class _FirstPlayerChoserState extends State<FirstPlayerChoser>
    with TickerProviderStateMixin {
  Map<int, Offset> touchPositions = <int, Offset>{};
  List<Widget> children = [];
  int? randomPlayer;
  var indicator;
  bool forceInReleaseMode = true;
  bool enabled = true;
  String? counter;
  double indicatorSize = 130;
  bool countInProgress = false;
  bool needToStopCount = false;
  var indicatorColor = const Color.fromARGB(255, 32, 184, 19);
  final List<Color> colors = <Color>[
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.deepPurpleAccent,
    Colors.indigoAccent,
    Colors.blueAccent,
    Colors.lightBlueAccent,
    Colors.cyanAccent,
    Colors.tealAccent,
    Colors.greenAccent,
    Colors.lightGreenAccent,
    Colors.limeAccent,
    Colors.yellowAccent,
    Colors.amberAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
  ];
  final List<Color> colorsSmall = <Color>[
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.black
  ];
  double fingerPrintsOpacity = 1.0;

  final Map<int, AnimationController> _colorControllers = {};
  final Map<int, Animation<Color?>> _colorAnimations = {};

  @override
  void initState() {
    super.initState();

    // Check "first player mode" system param
    SystemParameterSQL.selectSystemParameterById(3)
        .then((simpleIndicatorModeValue) {
      if (simpleIndicatorModeValue == null) {
        SystemParameterSQL.addSystemParameter(
                SystemParameter(id: 3, name: "simpleIndicatorMode", value: "1"))
            .then((value) {
          if (value == 0) developer.log("Cant insert param");
        });
      } else {
        simpleIndicatorMode = simpleIndicatorModeValue.value == "1";
        developer
            .log("simpleIndicatorMode = ${simpleIndicatorModeValue.value}");
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _colorControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Iterable<Widget> buildTouchIndicators() sync* {
    if (touchPositions.isNotEmpty) {
      for (var entry in touchPositions.entries) {
        final index = entry.key;
        final touchPosition = entry.value;
        final isRandomPlayer = index == randomPlayer;
        final newSize = indicatorSize;

        if (simpleIndicatorMode) {
          yield Positioned.directional(
            start: touchPosition.dx - newSize / 2,
            top: touchPosition.dy - newSize / 2,
            textDirection: TextDirection.ltr,
            child: AnimatedOpacity(
              opacity: isRandomPlayer ? 1.0 : fingerPrintsOpacity,
              duration: const Duration(seconds: 1),
              child: indicator != null
                  ? indicator!
                  : AnimatedContainer(
                      width: indicatorSize,
                      height: indicatorSize,
                      duration: const Duration(seconds: 1),
                      decoration: BoxDecoration(
                        color: colors[Random().nextInt(colors.length)],
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          );
        } else {
          if (!_colorControllers.containsKey(index)) {
            _colorControllers[index] = AnimationController(
              duration: const Duration(seconds: 10),
              vsync: this,
            )..repeat(reverse: true);

            _colorAnimations[index] = TweenSequence<Color?>(
              [
                for (var i = 0; i < colors.length; i++)
                  TweenSequenceItem<Color?>(
                    tween: ColorTween(
                      begin: colors[i],
                      end: colors[(i + 1) % colors.length],
                    ),
                    weight: 1,
                  ),
              ],
            ).animate(_colorControllers[index]!);
          }

          yield Positioned.directional(
            start: touchPosition.dx - newSize / 2,
            top: touchPosition.dy - newSize / 2,
            textDirection: TextDirection.ltr,
            child: AnimatedOpacity(
              opacity: isRandomPlayer ? 1.0 : fingerPrintsOpacity,
              duration: const Duration(seconds: 1),
              child: indicator != null
                  ? indicator!
                  : AnimatedContainer(
                      width: newSize,
                      height: newSize,
                      duration: const Duration(seconds: 1),
                      child: AnimatedBuilder(
                        animation: _colorAnimations[index]!,
                        builder: (context, child) {
                          return Icon(
                            Icons.fingerprint,
                            color: _colorAnimations[index]!.value,
                            size: newSize,
                          );
                        },
                      ),
                    ),
            ),
          );
        }
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
      fingerPrintsOpacity = 1.0;
      counter = S.of(context).touchTheScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold to get screen touch events
    var child = Scaffold(
      body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: FittedBox(
              child: Text(
            selectionColor: Colors.tealAccent,
            counter ?? S.of(context).touchTheScreen,
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
        if (countInProgress) {
          needToStopCount = true;
        }
        savePointerPosition(opm.pointer, opm.position);
        checkTouchPositions(touchPositions.length);
      },
      onPointerCancel: (opc) {
        if (touchPositions.isEmpty) {
          needToStopCount = false;
        }
        clearPointerPosition(opc.pointer);
      },
      onPointerUp: (opc) {
        if (touchPositions.isEmpty) {
          needToStopCount = false;
        }
        clearPointerPosition(opc.pointer);
      },
      child: Stack(children: children),
    );
  }

  void checkTouchPositions(int firstPositionsCount) async {
    if (touchPositions.length == firstPositionsCount) {
      if (touchPositions.length > 1) {
        setState(() {
          counter = "3";
          countInProgress = true;
        });
      } else {
        setState(() {
          counter = S.of(context).waitingForYourFriends;
        });
        countInProgress = false;
        return;
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if (needToStopCount) {
      needToStopCount = false;
      return;
    }

    if (touchPositions.length == firstPositionsCount) {
      if (touchPositions.length > 1) {
        setState(() {
          counter = "2";
        });
      } else {
        setState(() {
          counter = S.of(context).touchTheScreen;
        });
      }
    } else {
      countInProgress = false;
      return;
    }

    await Future.delayed(const Duration(seconds: 1));
    if (needToStopCount) {
      needToStopCount = false;
      return;
    }

    if (touchPositions.length == firstPositionsCount &&
        touchPositions.length > 1) {
      setState(() {
        counter = "1";
      });
    } else {
      countInProgress = false;
      return;
    }

    await Future.delayed(const Duration(seconds: 1));
    if (needToStopCount) {
      needToStopCount = false;
      return;
    }

    if (touchPositions.length == firstPositionsCount) {
      if (touchPositions.length > 1) {
        randomPlayer = ((touchPositions.keys).toList()..shuffle()).first;
        setState(() {
          counter = "";
          fingerPrintsOpacity = 0.0;
        });
        await Future.delayed(const Duration(seconds: 1));
        countInProgress = false;
      }
    } else {
      return;
    }
  }
}
