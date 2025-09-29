import 'package:flutter/material.dart';
import '../globals.dart';
import '../s.dart';
import 'package:intl/intl.dart';

// Создать текст с автоподбором размера
Widget buildScaledText(BuildContext context, String text, bool isSelected) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      text,
      maxLines: 1,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            fontSize: isSelected ? 14 : 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
    ),
  );
}

// Обновленная функция с передачей вычисленного размера шрифта
Widget buildScaledTextWithFont(
    BuildContext context, String text, bool isSelected, double fontSize) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      text,
      maxLines: 1,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            fontSize: fontSize, // Используем вычисленный размер
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
    ),
  );
}

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
      duration: const Duration(seconds: messageDuration),
      content: Text(message),
    ),
  );
}

String getUserDateFormatYY(String dateString) {
  DateTime date = DateTime.parse(dateString);

  final formatter = DateFormat('yyyy', S.currentLocale.languageCode);

  return formatter.format(date);
}

String getUserDateFormatMMMMdd(String dateString) {
  DateTime date = DateTime.parse(dateString);

  final formatter = DateFormat('dd MMMM', S.currentLocale.languageCode);

  return formatter.format(date);
}
