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

    // Проверяем переход именно на вкладку CalendarPlays (index = 2)
    if (index == 2 && oldIndex != 2) {
      print("nav callback");
      if (_refreshChildCallback != null) {
        _refreshChildCallback!();
      }
    }
  }

  // Переопределение метода для кастомного отображения
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildCustomNavigationBar(context),
      body: IndexedStack(
        index: currentPageIndex,
        children: <Widget>[
          LogPage(),
          Statistics(),
          calendarPlays,
          GameHelper(),
          FirstPlayerChoser(),
        ],
      ),
    );
  }

  Widget _buildCustomNavigationBar(BuildContext context) {
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
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: Icons.leaderboard_outlined,
              activeIcon: Icons.leaderboard,
              label: S.of(context).statistics,
              key: tutorialHandler.statsKey,
            ),
            _buildNavItem(
              context,
              index: 2,
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month,
              label: "Calendar",
              key: tutorialHandler.calendarKey,
            ),
            _buildNavItem(
              context,
              index: 3,
              icon: Icons.casino_outlined,
              activeIcon: Icons.smart_toy,
              label: S.of(context).chooseAGame,
              key: tutorialHandler.gameChoseKey,
            ),
            _buildNavItem(
              context,
              index: 4,
              icon: Icons.sentiment_satisfied_alt,
              activeIcon: Icons.insert_emoticon,
              label: S.of(context).firstPlayer,
              key: tutorialHandler.firstPlayerKey,
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
            buildScaledText(context, label, isSelected),
          ],
        ),
      ),
    );
  }
}
