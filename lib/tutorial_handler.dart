import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../s.dart';
import 'globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialHandler {
  TutorialHandler({required this.parentContext, required this.setPageMethod});
  dynamic parentContext;
  dynamic setPageMethod;

  static BuildContext? statsFiltersKeyContext;
  static BuildContext? statsFirstPlaysKeyContext;
  static BuildContext? statsExportTableKeyContext;

  late TutorialCoachMark tutorialCoachMark;
  GlobalKey logKey = GlobalKey(debugLabel: 'logKey');
  GlobalKey statsKey = GlobalKey(debugLabel: 'statsKey');
  GlobalKey gameChoseKey = GlobalKey(debugLabel: 'gameChoseKey');
  GlobalKey firstPlayerKey = GlobalKey(debugLabel: 'firstPlayerKey');

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
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "log",
        keyTarget: logKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(S.of(context).saveYourResults, "");
            },
          ),
        ],
      )
    ];

    targets.add(TargetFocus(
      identify: "progressBar",
      keyTarget: progressBarKey,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return _buildTutorialContent(
                S.of(context).initialLoadingCanBeLong, "");
          },
        ),
      ],
    ));

    targets.add(TargetFocus(
      identify: "selectGame",
      keyTarget: selectGameButtonKey,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) {
            return _buildTutorialContent(S.of(context).selectGameFromList, "");
          },
        ),
      ],
    ));

    targets.add(TargetFocus(
      keyTarget: recognizeGameButtonKey,
      identify: "recognizeGame",
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) {
            return _buildTutorialContent(S.of(context).orRecognizeGame, "");
          },
        ),
      ],
    ));

    targets.add(TargetFocus(
      keyTarget: swapSearchModeKey,
      identify: "swapSearchMode",
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) {
            return _buildTutorialContent(S.of(context).selectSearchMode, "");
          },
        ),
      ],
    ));

    return targets;
  }

  void _switchToStatisticsAndShowTutorial() {
    _showStatisticsTutorial();
  }

  void _showStatisticsTutorial() {
    TutorialCoachMark(
      targets: _createStatisticsTargets(),
      colorShadow: Colors.green.withOpacity(0.8),
      textSkip: S.of(parentContext).skip,
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
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "stats_global",
        keyTarget: statsKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                S.of(context).checkYourGameStats,
                S.of(context).playsCanBeEdited,
              );
            },
          ),
        ],
      )
    ];

    if (statsFiltersKeyContext != null) {
      final buttonBox =
          statsFiltersKeyContext!.findRenderObject() as RenderBox?;
      if (buttonBox != null && buttonBox.hasSize) {
        targets.add(TargetFocus(
          identify: "statsFiltersKey",
          targetPosition: TargetPosition(
            buttonBox.size,
            buttonBox.localToGlobal(Offset.zero),
          ),
          radius: 12,
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
        ));
      }
    }
    if (statsFirstPlaysKeyContext != null) {
      final buttonBox =
          statsFirstPlaysKeyContext!.findRenderObject() as RenderBox?;
      if (buttonBox != null && buttonBox.hasSize) {
        targets.add(TargetFocus(
          identify: "stats_first_plays",
          targetPosition: TargetPosition(
            buttonBox.size,
            buttonBox.localToGlobal(Offset.zero),
          ),
          radius: 12,
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
        ));
      }
    }
    if (statsExportTableKeyContext != null) {
      final buttonBox =
          statsExportTableKeyContext!.findRenderObject() as RenderBox?;
      if (buttonBox != null && buttonBox.hasSize) {
        targets.add(TargetFocus(
          identify: "stats_export_table",
          targetPosition: TargetPosition(
            buttonBox.size,
            buttonBox.localToGlobal(Offset.zero),
          ),
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return _buildTutorialContent(
                    S.of(context).exportYourStatsToCsv, "");
              },
            ),
          ],
        ));
      }
    }

    targets.add(TargetFocus(
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
    ));
    targets.add(TargetFocus(
      color: Colors.lime,
      identify: "first_player",
      keyTarget: firstPlayerKey,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) {
            return _buildTutorialContent(S.of(context).chooseWhoGoesFirst, "");
          },
        ),
      ],
    ));
    return targets;
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
