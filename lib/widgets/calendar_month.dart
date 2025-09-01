import 'package:flutter/material.dart';
import '../models/bgg_play_model.dart';
import 'package:intl/intl.dart';
import '../s.dart';

class CalendarWidget extends StatefulWidget {
  final int year;
  final int month;
  final List<BggPlay> bggPlays;
  final Function(DateTime?, List<BggPlay>)
      onDateTap; // Изменили тип на DateTime?
  final DateTime? selectedDate;

  const CalendarWidget({
    super.key,
    required this.year,
    required this.month,
    required this.bggPlays,
    required this.onDateTap,
    this.selectedDate,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late List<List<DateTime?>> _weeks;

  @override
  void initState() {
    super.initState();
    _generateCalendar();
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.year != widget.year ||
        oldWidget.month != widget.month) {
      _generateCalendar();
    }
  }

  List<String> getLocalizedWeekdays(BuildContext context, {bool short = true}) {
    final locale = S.currentLocale.languageCode;

    // Создаем дату, которая является понедельником
    final date = DateTime(2023, 1, 2); // 2 января 2023 - понедельник

    return List.generate(7, (index) {
      final currentDay = date.add(Duration(days: index));
      final format =
          short ? 'E' : 'EEEE'; // 'E' - короткое название, 'EEEE' - полное
      return DateFormat(format, locale).format(currentDay);
    });
  }

  List<String> getLocalizedMonths(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return List.generate(12, (index) {
      final date = DateTime(2023, index + 1);
      return DateFormat('MMMM', locale).format(date);
    });
  }

  void _generateCalendar() {
    final firstDay = DateTime(widget.year, widget.month, 1);
    final lastDay = DateTime(widget.year, widget.month + 1, 0);

    int firstWeekday = firstDay.weekday;
    int totalDays = lastDay.day;

    List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);

    // Добавляем пустые дни в первую неделю
    for (int i = 0; i < firstWeekday - 1; i++) {
      currentWeek[i] = null;
    }

    // Заполняем календарь днями
    for (int day = 1; day <= totalDays; day++) {
      int weekIndex = firstWeekday - 1;
      currentWeek[weekIndex] = DateTime(widget.year, widget.month, day);

      if (weekIndex == 6 || day == totalDays) {
        weeks.add(List.from(currentWeek));
        currentWeek = List.filled(7, null);
      }
      firstWeekday = (firstWeekday % 7) + 1;
    }

    setState(() {
      _weeks = weeks;
    });
  }

  String get _monthTitle {
    var months = getLocalizedMonths(context);
    return '${months[widget.month - 1]} ${widget.year}';
  }

  int _getEventCount(DateTime date) {
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    return widget.bggPlays.where((play) => play.date == formattedDate).length;
  }

  List<BggPlay> _getPlaysForDate(DateTime date) {
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    return widget.bggPlays.where((play) => play.date == formattedDate).toList();
  }

  // Проверяем, является ли дата выбранной
  bool _isDateSelected(DateTime date) {
    return widget.selectedDate != null &&
        widget.selectedDate!.year == date.year &&
        widget.selectedDate!.month == date.month &&
        widget.selectedDate!.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _monthTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Table(
          children: [
            TableRow(
              children: getLocalizedWeekdays(context)
                  .map((e) => _DayTitle(e))
                  .toList(),
            ),
            ..._weeks.map((week) => TableRow(
                  children: week
                      .map((date) => _DayCell(
                            date: date,
                            eventCount: date != null ? _getEventCount(date) : 0,
                            isSelected: date != null && _isDateSelected(date),
                            onTap: date != null
                                ? () {
                                    // Если дата уже выбрана, снимаем выделение
                                    if (_isDateSelected(date)) {
                                      widget.onDateTap(null, []);
                                    } else {
                                      // Иначе выделяем новую дату
                                      List<BggPlay> playsForDate =
                                          _getPlaysForDate(date);
                                      widget.onDateTap(date, playsForDate);
                                    }
                                  }
                                : null,
                          ))
                      .toList(),
                )),
          ],
        ),
      ],
    );
  }
}

class _DayTitle extends StatelessWidget {
  final String title;

  const _DayTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime? date;
  final int eventCount;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DayCell({
    required this.date,
    required this.eventCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          color: isSelected ? Colors.blue : Colors.transparent,
        ),
        child: Stack(
          children: [
            // Число дня вверху по центру
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  date != null ? date!.day.toString() : '',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (date != null ? Colors.black : Colors.transparent),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),

            // Зеленый круг с количеством событий внизу по центру
            if (eventCount > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.green,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        eventCount.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
