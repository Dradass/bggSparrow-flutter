import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/pages/log_page.dart';
import 'package:flutter_application_1/pages/game_choose.dart';
import 'package:flutter_application_1/pages/first_player.dart';
import 'package:flutter_application_1/pages/statistics.dart';

/// Flutter code sample for [NavigationBar].

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      // appBar: AppBar(
      //     title: Text(backgroundLoading ? "Loading" : "Loading completed")),
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
            label: 'Choose a game',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.insert_emoticon),
            icon: Icon(Icons.sentiment_satisfied_alt),
            label: 'First player',
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: const <Widget>[
          /// Home page
          LogScaffold(),
          Statistics(),
          GameHelper(),
          FirstPlayerChoser(),
        ],
      ),
    );
  }
}
