library touch_indicator;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Adds touch indicators to the screen whenever a touch occurs
///
/// This can be useful when recording videos of an app where you want to show
/// where the user has tapped. Can also be useful when running integration
/// tests or when giving demos with a screencast.
class TouchIndicator extends StatefulWidget {
  /// The child on which to show indicators
  final Widget child;

  /// The size of the indicator
  final double indicatorSize;

  /// The color of the indicator
  final Color indicatorColor;

  /// Overrides the default indicator.
  ///
  /// Make sure to set the proper [indicatorSize] to align the widget properly
  final Widget? indicator;

  /// If set to true, shows indicators in release mode as well
  final bool forceInReleaseMode;

  /// If set to false, disables the indicators from showing
  final bool enabled;

  /// Creates a touch indicator canvas
  ///
  /// Touch indicators are shown on the child whenever a touch occurs
  const TouchIndicator({
    Key? key,
    required this.child,
    this.indicator,
    this.indicatorSize = 60.0,
    this.indicatorColor = Colors.blueGrey,
    this.forceInReleaseMode = false,
    this.enabled = true,
  }) : super(key: key);

  @override
  _TouchIndicatorState createState() => _TouchIndicatorState();
}

class _TouchIndicatorState extends State<TouchIndicator> {
  Map<int, Offset> touchPositions = <int, Offset>{};
  List<Widget> children = [];
  int? randomPlayer = null;

  Iterable<Widget> buildTouchIndicators() sync* {
    if (touchPositions.isNotEmpty) {
      for (var touchPosition in touchPositions.values) {
        yield Positioned.directional(
          start: touchPosition.dx - widget.indicatorSize / 2,
          top: touchPosition.dy - widget.indicatorSize / 2,
          textDirection: TextDirection.ltr,
          child: widget.indicator != null
              ? widget.indicator!
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.indicatorColor.withOpacity(0.3),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: widget.indicatorSize,
                    color: widget.indicatorColor.withOpacity(0.9),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if ((kReleaseMode && !widget.forceInReleaseMode) || !widget.enabled) {
      return widget.child;
    }

    children = [
      widget.child,
      ...buildTouchIndicators(),
    ];
    //children = [widget.child];
    print("build children = $children");
    if (touchPositions.length > 0) {
      //checkTouchPositions(touchPositions.length);
      //print(children);
      print(touchPositions);
      //var winner = Random().nextInt(children.length - 1) + 1;
      // setState(() {
      //   for (var i = 1; i < children.length; i++) {
      //     children[i] = Positioned.directional(
      //       textDirection: TextDirection.ltr,
      //       child: widget.indicator != null
      //           ? widget.indicator!
      //           : Container(
      //               decoration: BoxDecoration(
      //                 shape: BoxShape.circle,
      //                 color: widget.indicatorColor.withOpacity(0.3),
      //               ),
      //               child: Icon(
      //                 Icons.fingerprint,
      //                 size: 0,
      //                 color: Colors.cyan,
      //               ),
      //             ),
      //     );
      //   }
      //   // children[1] = Positioned.directional(
      //   //   textDirection: TextDirection.ltr,
      //   //   child: widget.indicator != null
      //   //       ? widget.indicator!
      //   //       : Container(
      //   //           decoration: BoxDecoration(
      //   //             shape: BoxShape.circle,
      //   //             color: widget.indicatorColor.withOpacity(0.3),
      //   //           ),
      //   //           child: Icon(
      //   //             Icons.fingerprint,
      //   //             size: widget.indicatorSize * 2,
      //   //             color: Colors.cyan,
      //   //           ),
      //   //         ),
      //   // );
      // });
    }

    return Listener(
      onPointerDown: (opm) {
        print('onPointerDown');
        print("down children = $children");
        savePointerPosition(opm.pointer, opm.position);
        checkTouchPositions(touchPositions.length);
        // setState(() {
        //   var newChild = Positioned.directional(
        //     start: 50 - widget.indicatorSize / 2,
        //     top: 50 - widget.indicatorSize / 2,
        //     textDirection: TextDirection.ltr,
        //     child: widget.indicator != null
        //         ? widget.indicator!
        //         : Container(
        //             decoration: BoxDecoration(
        //               shape: BoxShape.circle,
        //               color: widget.indicatorColor.withOpacity(0.3),
        //             ),
        //             child: Icon(
        //               Icons.fingerprint,
        //               size: widget.indicatorSize * 2,
        //               color: widget.indicatorColor.withOpacity(0.9),
        //             ),
        //           ),
        //   );

        //   children.add(newChild);
        // });
      },
      // onPointerMove: (opm) {
      //   print('savePointerPosition');
      //   savePointerPosition(opm.pointer, opm.position);
      //   print(touchPositions);
      // },
      onPointerCancel: (opc) {
        clearPointerPosition(opc.pointer);
        print('onPointerCancel');
      },
      onPointerUp: (opc) {
        print('onPointerUp');
        clearPointerPosition(opc.pointer);
      },
      child: Stack(children: children),
    );
  }

  void checkTouchPositions(int firstPositionsCount) async {
    print(touchPositions);
    await Future.delayed(const Duration(seconds: 3));
    print(touchPositions);
    if (touchPositions.length == firstPositionsCount) {
      print("success");
      if (touchPositions.length > 0) {
        randomPlayer = ((touchPositions.keys).toList()..shuffle()).first;
        for (var position in (touchPositions.keys).toList()..shuffle()) {
          if (position != randomPlayer) {
            touchPositions[position] = Offset(-100, -100);
            savePointerPosition(position, touchPositions[position]!);
          }
        }
        // setState(() {
        //   children[0] = Positioned.directional(
        //     start: 0,
        //     top: 0,
        //     textDirection: TextDirection.ltr,
        //     child: widget.indicator != null
        //         ? widget.indicator!
        //         : Container(
        //             decoration: BoxDecoration(
        //               shape: BoxShape.circle,
        //               color: widget.indicatorColor.withOpacity(0.3),
        //             ),
        //             child: Icon(
        //               Icons.fingerprint,
        //               size: widget.indicatorSize,
        //               color: Colors.cyan,
        //             ),
        //           ),
        //   );
        // });
        print(children);
        // Positioned child = children[1] as Positioned;
        // var childContainer = child.child as Container;
        // childContainer.decoration = DecoratedSliver

        for (var i = 1; i < children.length; i++) {
          print('remove = $i');

          //children.remove(children[i]);
          // children[i] = Positioned.directional(
          //   textDirection: TextDirection.ltr,
          //   child: widget.indicator != null
          //       ? widget.indicator!
          //       : Container(
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             color: widget.indicatorColor.withOpacity(0.3),
          //           ),
          //           child: Icon(
          //             Icons.fingerprint,
          //             size: 0,
          //             color: Colors.cyan,
          //           ),
          //         ),
          // );

          //print(children);
        }
      }
    }
    print(touchPositions);
  }
}
