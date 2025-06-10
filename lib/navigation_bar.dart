import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/log_page.dart';
import 'package:flutter_application_1/pages/game_choose.dart';
import 'package:flutter_application_1/pages/first_player.dart';
import 'package:flutter_application_1/pages/statistics.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../s.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentPageIndex = 0;

  late TutorialCoachMark tutorialCoachMark;
  GlobalKey logKey = GlobalKey();
  GlobalKey logSelectGameKey = GlobalKey();
  GlobalKey logRecognizeGameKey = GlobalKey();
  GlobalKey statsKey = GlobalKey();
  GlobalKey gameChoseKey = GlobalKey();
  GlobalKey firstPlayerKey = GlobalKey();
  final GlobalKey statsFiltersKey = GlobalKey();
  final GlobalKey statsFirstPlaysKey = GlobalKey();
  final GlobalKey statsExportTableKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('first_launch_nav') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('first_launch_nav', false);
      _createTutorial();
      Future.delayed(const Duration(milliseconds: 500), () {
        tutorialCoachMark.show(context: context);
      });
    }
  }

  void _createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.blue.withOpacity(0.8),
      textSkip: S.of(context).skip,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        setState(() => currentPageIndex = 1);
        _switchToStatisticsAndShowTutorial();
      },
    );
  }

  List<TargetFocus> _createTargets() {
    return [
      TargetFocus(
        identify: "log",
        keyTarget: logKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).saveYourResults,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "selectGame",
        keyTarget: logSelectGameKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).selectGameFromList,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "recognizeGame",
        keyTarget: logRecognizeGameKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).orRecognizeGame,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];
  }

  void _switchToStatisticsAndShowTutorial() {
    _showStatisticsTutorial();
  }

  void _showStatisticsTutorial() {
    TutorialCoachMark(
      targets: _createStatisticsTargets(),
      colorShadow: Colors.green.withOpacity(0.8),
      textSkip: "Skip",
      paddingFocus: 10,
      onClickTarget: (target) {
        if (target.identify == "stats_export_table") {
          setState(() => currentPageIndex = 2);
        }
        if (target.identify == "game_choose") {
          setState(() => currentPageIndex = 3);
        }
      },
    ).show(context: context);
  }

  List<TargetFocus> _createStatisticsTargets() {
    return [
      TargetFocus(
        identify: "stats_global",
        keyTarget: statsKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                S.of(context).checkYourGameStats,
                "",
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "stats_filters",
        keyTarget: statsFiltersKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                S.of(context).adjustFilters,
                "",
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "stats_first_plays",
        keyTarget: statsFirstPlaysKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                S.of(context).findYourFirstMatches,
                "",
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "stats_export_table",
        keyTarget: statsExportTableKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                S.of(context).exportYourStatsToCsv,
                "",
              );
            },
          ),
        ],
      ),
      TargetFocus(
        color: Colors.orange,
        identify: "game_choose",
        keyTarget: gameChoseKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                S.of(context).chooseRandomGameToPlay,
                S.of(context).playerVotesAreCounted,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        color: Colors.lime,
        identify: "first_player",
        keyTarget: firstPlayerKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                S.of(context).chooseWhoGoesFirst,
                "",
              );
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildTutorialContent(String title, String description) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
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
            selectedIcon: Icon(Icons.archive, key: logKey),
            icon: Icon(Icons.archive_outlined, key: logKey),
            label: S.of(context).logPlayShort,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.leaderboard, key: statsKey),
            icon: Icon(Icons.leaderboard_outlined, key: statsKey),
            label: S.of(context).statistics,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.smart_toy, key: gameChoseKey),
            icon: Icon(Icons.casino_outlined, key: gameChoseKey),
            label: S.of(context).chooseAGame,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.insert_emoticon, key: firstPlayerKey),
            icon: Icon(Icons.sentiment_satisfied_alt, key: firstPlayerKey),
            label: S.of(context).firstPlayer,
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: <Widget>[
          LogScaffold(
              selectGameKey: logSelectGameKey,
              recognizeGameKey: logRecognizeGameKey),
          Statistics(
              filtersKey: statsFiltersKey,
              firstPlaysKey: statsFirstPlaysKey,
              exportTableKey: statsExportTableKey),
          const GameHelper(),
          const FirstPlayerChoser(),
        ],
      ),
    );
  }
}
