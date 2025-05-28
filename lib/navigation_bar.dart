import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/log_page.dart';
import 'package:flutter_application_1/pages/game_choose.dart';
import 'package:flutter_application_1/pages/first_player.dart';
import 'package:flutter_application_1/pages/statistics.dart';
import '../s.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: const Icon(Icons.archive),
            icon: const Icon(Icons.archive_outlined),
            label: S.of(context).logPlayShort,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.leaderboard),
            icon: const Icon(Icons.leaderboard_outlined),
            label: S.of(context).statistics,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.smart_toy),
            icon: const Icon(Icons.casino_outlined),
            label: S.of(context).chooseAGame,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.insert_emoticon),
            icon: const Icon(Icons.sentiment_satisfied_alt),
            label: S.of(context).firstPlayer,
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: const <Widget>[
          LogScaffold(),
          Statistics(),
          GameHelper(),
          FirstPlayerChoser(),
        ],
      ),
    );
  }
}
