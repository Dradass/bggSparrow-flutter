import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/log_page.dart';
import 'package:flutter_application_1/pages/game_choose.dart';
import 'package:flutter_application_1/pages/first_player.dart';
import 'package:flutter_application_1/pages/statistics.dart';
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

  @override
  void initState() {
    super.initState();
    tutorialHandler = TutorialHandler(
        parentContext: context, setPageMethod: () => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tutorialHandler.checkFirstLaunch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('nav_bar'),
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.archive, key: tutorialHandler.logKey),
            icon: Icon(Icons.archive_outlined),
            label: S.of(context).logPlayShort,
          ),
          NavigationDestination(
            selectedIcon:
                Icon(Icons.leaderboard, key: tutorialHandler.statsKey),
            icon: Icon(Icons.leaderboard_outlined),
            label: S.of(context).statistics,
          ),
          NavigationDestination(
            selectedIcon:
                Icon(Icons.smart_toy, key: tutorialHandler.gameChoseKey),
            icon:
                Icon(Icons.casino_outlined, key: tutorialHandler.gameChoseKey),
            label: S.of(context).chooseAGame,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.insert_emoticon,
                key: tutorialHandler.firstPlayerKey),
            icon: Icon(Icons.sentiment_satisfied_alt),
            label: S.of(context).firstPlayer,
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: <Widget>[
          LogPage(),
          Statistics(),
          const GameHelper(),
          const FirstPlayerChoser(),
        ],
      ),
    );
  }
}
