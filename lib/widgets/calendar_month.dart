import 'package:flutter/material.dart';
import '../models/bgg_play_model.dart';

class CalendarWidget extends StatefulWidget {
  final int year;
  final int month;
  final List<BggPlay> bggPlays; // Список объектов BggPlay
  final Function(List<BggPlay>) onDateTap; // Колбек для передачи списка BggPlay

  const CalendarWidget({
    super.key,
    required this.year,
    required this.month,
    required this.bggPlays,
    required this.onDateTap,
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

    _weeks = weeks;
  }

  String get _monthTitle {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];
    return '${months[widget.month - 1]} ${widget.year}';
  }

  int _getEventCount(DateTime date) {
    // Форматируем дату для сравнения с PlayDate
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // Подсчитываем количество BggPlay с этой датой
    return widget.bggPlays.where((play) => play.date == formattedDate).length;
  }

  List<BggPlay> _getPlaysForDate(DateTime date) {
    // Форматируем дату для сравнения с PlayDate
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // Возвращаем все BggPlay с этой датой
    return widget.bggPlays.where((play) => play.date == formattedDate).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Заголовок с названием месяца и года
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _monthTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Сетка календаря
        Table(
          children: [
            // Заголовок с днями недели
            const TableRow(
              children: [
                _DayTitle('Пн'),
                _DayTitle('Вт'),
                _DayTitle('Ср'),
                _DayTitle('Чт'),
                _DayTitle('Пт'),
                _DayTitle('Сб'),
                _DayTitle('Вс'),
              ],
            ),
            // Ячейки с днями месяца
            ..._weeks.map((week) => TableRow(
                  children: week
                      .map((date) => _DayCell(
                            date: date,
                            eventCount: date != null ? _getEventCount(date) : 0,
                            onTap: date != null
                                ? () {
                                    // Получаем все BggPlay для этой даты и передаем через колбек
                                    List<BggPlay> playsForDate =
                                        _getPlaysForDate(date);
                                    widget.onDateTap(playsForDate);
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

// Виджет для заголовка дня недели
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

// Виджет для ячейки дня (без изменений)
class _DayCell extends StatelessWidget {
  final DateTime? date;
  final int eventCount;
  final VoidCallback? onTap;

  const _DayCell({
    required this.date,
    required this.eventCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
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
                    color: date != null ? Colors.black : Colors.transparent,
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
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        eventCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
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
