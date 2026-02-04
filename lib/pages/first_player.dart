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
  List<int?> randomPlayers = [];
  var indicator;
  bool forceInReleaseMode = true;
  bool enabled = true;
  String? counter;
  double baseIndicatorSize = 130; // Базовый размер для пульсации
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

  final Map<int, AnimationController> _sizeControllers = {};
  final Map<int, Animation<double>> _sizeAnimations = {};
  final Map<int, AnimationController> _colorControllers = {};
  final Map<int, Animation<Color?>> _colorAnimations = {};
  final Map<int, int> _startColorIndex =
      {}; // Стартовый индекс цвета для каждого индикатора

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
    for (var controller in _sizeControllers.values) {
      controller.dispose();
    }
    for (var controller in _colorControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations(int index) {
    // Инициализируем анимацию размера (пульсация)
    if (!_sizeControllers.containsKey(index)) {
      _sizeControllers[index] = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);

      _sizeAnimations[index] = TweenSequence<double>(
        [
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0.85, end: 1.15),
            weight: 50,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.15, end: 0.85),
            weight: 50,
          ),
        ],
      ).animate(
        CurvedAnimation(
          parent: _sizeControllers[index]!,
          curve: Curves.easeInOut,
        ),
      );
    }

    // Инициализируем анимацию цвета (только для сложного режима)
    if (!simpleIndicatorMode && !_colorControllers.containsKey(index)) {
      // Генерируем уникальный стартовый цвет для каждого индикатора
      _startColorIndex[index] = Random().nextInt(colors.length);

      _colorControllers[index] = AnimationController(
        duration: const Duration(
            seconds: 8), // Уникальная скорость для каждого индикатора
        vsync: this,
      )..repeat(); // Непрерывная анимация

      // Создаем уникальную анимацию для каждого индикатора с разной скоростью
      final startColor = colors[_startColorIndex[index]!];
      final speedMultiplier =
          0.5 + Random().nextDouble() * 1.5; // От 0.5x до 2x скорости

      // Создаем плавную анимацию с использованием собственной логики интерполяции
      _colorAnimations[index] = ColorTween(
        begin: startColor,
        end: startColor,
      ).animate(
        CurvedAnimation(
          parent: _colorControllers[index]!,
          curve: Curves.linear,
        ),
      );

      // Начинаем со случайной позиции
      _colorControllers[index]!.value = Random().nextDouble();

      // Устанавливаем скорость анимации
      _colorControllers[index]!.duration =
          Duration(milliseconds: (8000 * speedMultiplier).toInt());
    }
  }

  // Получаем текущий цвет для индикатора
  Color _getCurrentColor(double progress, int index) {
    // Каждый индикатор имеет свой уникальный стартовый цвет
    final startIndex = _startColorIndex[index]!;

    // Добавляем смещение для уникальности
    final offset =
        index * (colors.length / 10); // Разное смещение для каждого индикатора

    // Создаем плавный переход через цветовой спектр
    final effectiveProgress = (progress + offset) % 1.0;
    final totalColors = colors.length;
    final scaledValue = effectiveProgress * totalColors;

    final colorIndex1 = scaledValue.floor() % totalColors;
    final colorIndex2 = (colorIndex1 + 1) % totalColors;
    final t = scaledValue - scaledValue.floor();

    // Плавная интерполяция с использованием HSL для лучших переходов
    return _lerpHSLC(colors[colorIndex1], colors[colorIndex2], t);
  }

  // Плавная интерполяция цветов в пространстве HSL
  Color _lerpHSLC(Color a, Color b, double t) {
    // Конвертируем в HSL
    final aHSL = HSLColor.fromColor(a);
    final bHSL = HSLColor.fromColor(b);

    // Плавно интерполируем каждый компонент HSL
    final hue = _lerpAngle(aHSL.hue, bHSL.hue, t);
    final saturation =
        aHSL.saturation + (bHSL.saturation - aHSL.saturation) * t;
    final lightness = aHSL.lightness + (bHSL.lightness - aHSL.lightness) * t;

    return HSLColor.fromAHSL(a.alpha / 255.0, hue, saturation, lightness)
        .toColor();
  }

  // Плавная интерполяция углов (для hue)
  double _lerpAngle(double a, double b, double t) {
    // Нормализуем углы
    a = a % 360;
    b = b % 360;

    // Выбираем кратчайший путь
    final delta = b - a;
    if (delta.abs() > 180) {
      if (b > a) {
        return (a + (delta - 360) * t) % 360;
      } else {
        return (a + (delta + 360) * t) % 360;
      }
    }
    return (a + delta * t) % 360;
  }

  // Получаем фиксированный уникальный цвет для простого режима
  Color _getUniqueFixedColor(int index) {
    // Используем индекс индикатора для генерации уникального цвета
    final colorIndex = (index * 3) % colors.length;
    return colors[colorIndex];
  }

  Iterable<Widget> buildTouchIndicators() sync* {
    if (touchPositions.isNotEmpty) {
      for (var entry in touchPositions.entries) {
        final index = entry.key;
        final touchPosition = entry.value;
        final isRandomPlayer = randomPlayers.contains(index);

        // Инициализируем анимации для этого индикатора
        _initializeAnimations(index);

        if (simpleIndicatorMode) {
          // Простой режим: уникальный фиксированный цвет для каждого индикатора
          final fixedColor = _getUniqueFixedColor(index);

          yield Positioned.directional(
            start: touchPosition.dx - baseIndicatorSize / 2,
            top: touchPosition.dy - baseIndicatorSize / 2,
            textDirection: TextDirection.ltr,
            child: AnimatedOpacity(
              opacity: isRandomPlayer ? 1.0 : fingerPrintsOpacity,
              duration: const Duration(seconds: 1),
              child: indicator != null
                  ? indicator!
                  : AnimatedBuilder(
                      animation: _sizeAnimations[index]!,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _sizeAnimations[index]!.value,
                          child: Container(
                            width: baseIndicatorSize,
                            height: baseIndicatorSize,
                            decoration: BoxDecoration(
                              color: fixedColor,
                              shape: BoxShape.circle,
                              // Добавляем уникальную тень в цвет индикатора
                              boxShadow: [
                                BoxShadow(
                                  color: fixedColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          );
        } else {
          // Сложный режим: уникальная плавная смена цветов для каждого индикатора
          yield Positioned.directional(
            start: touchPosition.dx - baseIndicatorSize / 2,
            top: touchPosition.dy - baseIndicatorSize / 2,
            textDirection: TextDirection.ltr,
            child: AnimatedOpacity(
              opacity: isRandomPlayer ? 1.0 : fingerPrintsOpacity,
              duration: const Duration(seconds: 1),
              child: indicator != null
                  ? indicator!
                  : AnimatedBuilder(
                      animation: Listenable.merge([
                        _sizeAnimations[index]!,
                        _colorControllers[index]!,
                      ]),
                      builder: (context, child) {
                        // Получаем текущий уникальный цвет
                        final progress = _colorControllers[index]!.value;
                        final currentColor = _getCurrentColor(progress, index);

                        return Transform.scale(
                          scale: _sizeAnimations[index]!.value,
                          child: Container(
                            width: baseIndicatorSize,
                            height: baseIndicatorSize,
                            decoration: BoxDecoration(
                              color: currentColor,
                              shape: BoxShape.circle,
                              // Уникальная тень в текущий цвет
                              boxShadow: [
                                BoxShadow(
                                  color: currentColor.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              color: Colors.white.withOpacity(0.9),
                              size: baseIndicatorSize * 0.7,
                            ),
                          ),
                        );
                      },
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

      // Останавливаем анимации при удалении указателя
      if (_sizeControllers.containsKey(index)) {
        _sizeControllers[index]!.dispose();
        _sizeControllers.remove(index);
        _sizeAnimations.remove(index);
      }
      if (_colorControllers.containsKey(index)) {
        _colorControllers[index]!.dispose();
        _colorControllers.remove(index);
        _colorAnimations.remove(index);
        _startColorIndex.remove(index);
      }
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
      if (touchPositions.length > firstPlayerWinnersCount) {
        setState(() {
          counter = "3";
          countInProgress = true;
          needToStopCount = false;
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
      if (touchPositions.length > firstPlayerWinnersCount) {
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
        touchPositions.length > firstPlayerWinnersCount) {
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
      if (touchPositions.length > firstPlayerWinnersCount) {
        randomPlayers = ((touchPositions.keys).toList()..shuffle())
            .take(firstPlayerWinnersCount)
            .toList();
        setState(() {
          counter = "";
          fingerPrintsOpacity = 0.0;
        });
        needToStopCount = true;
        await Future.delayed(const Duration(seconds: 1));
        countInProgress = false;
      }
    } else {
      return;
    }
  }
}
