import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/log_page.dart';
import 'package:flutter_application_1/pages/game_choose.dart';
import 'package:flutter_application_1/pages/first_player.dart';
import 'package:flutter_application_1/pages/statistics.dart';
import 'package:flutter_application_1/pages/calendar_plays.dart';
import '../widgets/common.dart';
import '../s.dart';
import 'globals.dart';
import 'tutorial_handler.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late TutorialHandler tutorialHandler;
  VoidCallback? _refreshChildCallback;
  late CalendarPlays calendarPlays;

  // Переменная для хранения вычисленного размера шрифта
  double? _calculatedFontSize;

  void _registerRefreshCallback(VoidCallback callback) {
    _refreshChildCallback = callback;
  }

  @override
  void initState() {
    super.initState();
    calendarPlays =
        CalendarPlays(onRefreshCallbackRegistered: _registerRefreshCallback);
    tutorialHandler = TutorialHandler(
        parentContext: context, setPageMethod: () => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tutorialHandler.checkFirstLaunch();
    });
  }

  void _onTabTapped(int index) {
    final oldIndex = currentPageIndex;
    setState(() => currentPageIndex = index);
    print("tab ${index}");

    if (index == 2 && oldIndex != 2) {
      print("nav callback");
      if (_refreshChildCallback != null) {
        _refreshChildCallback!();
      }
    }
  }

  // Функция для вычисления минимального размера шрифта
  double _calculateFontSize(BuildContext context, List<String> labels) {
    if (_calculatedFontSize != null) return _calculatedFontSize!;

    final TextTheme textTheme = Theme.of(context).textTheme;
    const double maxWidth = 80; // Максимальная ширина для одной вкладки
    const double minFontSize = 8; // Минимальный допустимый размер шрифта
    const double maxFontSize = 14; // Максимальный желаемый размер шрифта

    double calculatedSize = maxFontSize;

    // Создаем TextPainter для каждой надписи и находим минимальный размер
    for (String label in labels) {
      double currentSize = maxFontSize;

      while (currentSize >= minFontSize) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: textTheme.labelMedium?.copyWith(
              fontSize: currentSize,
              fontWeight: FontWeight.normal,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: maxWidth);

        if (textPainter.didExceedMaxLines || textPainter.width > maxWidth) {
          currentSize -= 0.5; // Уменьшаем размер
        } else {
          break; // Нашли подходящий размер для этой надписи
        }
      }

      // Берем минимальный размер из всех надписей
      if (currentSize < calculatedSize) {
        calculatedSize = currentSize;
      }
    }

    _calculatedFontSize = calculatedSize;
    return calculatedSize;
  }

  @override
  Widget build(BuildContext context) {
    // Получаем все надписи для вкладок
    final List<String> labels = [
      S.of(context).logPlayShort,
      S.of(context).statistics,
      S.of(context).calendar,
      S.of(context).chooseAGame,
      S.of(context).firstPlayer,
    ];

    // Вычисляем размер шрифта один раз
    final double fontSize = _calculateFontSize(context, labels);

    return Scaffold(
      bottomNavigationBar: _buildCustomNavigationBar(context, fontSize),
      body: IndexedStack(
        index: currentPageIndex,
        children: <Widget>[
          const LogPage(),
          const Statistics(),
          calendarPlays,
          const GameHelper(),
          const FirstPlayerChoser(),
        ],
      ),
    );
  }

  Widget _buildCustomNavigationBar(BuildContext context, double fontSize) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              index: 0,
              icon: Icons.archive_outlined,
              activeIcon: Icons.archive,
              label: S.of(context).logPlayShort,
              key: tutorialHandler.logKey,
              fontSize: fontSize,
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: Icons.leaderboard_outlined,
              activeIcon: Icons.leaderboard,
              label: S.of(context).statistics,
              key: tutorialHandler.statsKey,
              fontSize: fontSize,
            ),
            _buildNavItem(
              context,
              index: 2,
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month,
              label: S.of(context).calendar,
              key: tutorialHandler.calendarKey,
              fontSize: fontSize,
            ),
            _buildNavItem(
              context,
              index: 3,
              icon: Icons.casino_outlined,
              activeIcon: Icons.smart_toy,
              label: S.of(context).chooseAGame,
              key: tutorialHandler.gameChoseKey,
              fontSize: fontSize,
            ),
            _buildNavItem(
              context,
              index: 4,
              icon: Icons.sentiment_satisfied_alt,
              activeIcon: Icons.insert_emoticon,
              label: S.of(context).firstPlayer,
              key: tutorialHandler.firstPlayerKey,
              fontSize: fontSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Key key,
    required double fontSize,
  }) {
    final isSelected = currentPageIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          if (index == 2 && currentPageIndex != 2) {
            print("nav callback");
            if (_refreshChildCallback != null) {
              _refreshChildCallback!();
            }
          }
          currentPageIndex = index;
        }),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              key: key,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            buildScaledTextWithFont(context, label, isSelected, fontSize),
          ],
        ),
      ),
    );
  }
}
