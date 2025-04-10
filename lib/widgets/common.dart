import 'package:flutter/material.dart';
import '../globals.dart';

class FlexButton extends StatelessWidget {
  final Widget childWidget;
  final int flexValue;

  @override
  Widget build(BuildContext context) {
    return Flexible(
        flex: flexValue,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: childWidget));
  }

  const FlexButton(this.childWidget, this.flexValue, {super.key});
}

class FlexButtonSettings extends StatelessWidget {
  final Widget childWidget;
  final Widget settingsWidget;
  final int flexValue;

  @override
  Widget build(BuildContext context) {
    return Flexible(
        flex: flexValue,
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Row(
              children: [
                settingsWidget,
                Expanded(
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: childWidget))
              ],
            )));
  }

  const FlexButtonSettings(
      this.childWidget, this.settingsWidget, this.flexValue,
      {super.key});
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(seconds: messageDuration),
      content: Text(message),
    ),
  );
}
