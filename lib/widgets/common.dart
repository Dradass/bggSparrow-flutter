import 'package:flutter/material.dart';

class FlexButton extends StatelessWidget {
  Widget childWidget;
  int flexValue = 3;

  @override
  Widget build(BuildContext context) {
    return Flexible(
        flex: flexValue,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: childWidget));
  }

  FlexButton(this.childWidget, this.flexValue, {super.key});
}
