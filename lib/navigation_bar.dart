import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/log_page.dart';
import 'package:flutter_application_1/pages/game_helper.dart';
import 'package:flutter_application_1/pages/first_player.dart';

/// Flutter code sample for [NavigationBar].

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        //backgroundColor: Colors.amber,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        //indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.archive),
            icon: Icon(Icons.archive_outlined),
            label: 'Log play',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.leaderboard),
            icon: Icon(Icons.leaderboard_outlined),
            label: 'Statistics',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.smart_toy),
            icon: Icon(Icons.casino_outlined),
            label: 'Play helper',
          ),
        ],
      ),
      body: IndexedStack(
        children: <Widget>[
          /// Home page
          LogScaffold(),
          FirstPlayerChoser(),
          GameHelper()
        ],
        index: currentPageIndex,
      ),
    );
  }
}
