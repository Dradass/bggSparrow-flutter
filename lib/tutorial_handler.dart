import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../s.dart';
import 'globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialHandler {
  TutorialHandler({required this.parentContext, required this.setPageMethod});
  dynamic parentContext;
  dynamic setPageMethod;

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

  Future<void> checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('first_launch_nav') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('first_launch_nav', false);
      _createTutorial();
      Future.delayed(const Duration(milliseconds: 500), () {
        tutorialCoachMark.show(context: parentContext);
      });
    }
  }

  void setPageByIndex(int index) {
    currentPageIndex = index;
    setPageMethod();
  }

  void _createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.blue.withOpacity(0.8),
      textSkip: S.of(parentContext).skip,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        setPageByIndex(1);
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
          setPageByIndex(2);
        }
        if (target.identify == "game_choose") {
          setPageByIndex(3);
        }
      },
    ).show(context: parentContext);
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
}
