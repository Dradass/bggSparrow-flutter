import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/log_page.dart';
import 'package:flutter_application_1/pages/game_choose.dart';
import 'package:flutter_application_1/pages/first_player.dart';
import 'package:flutter_application_1/pages/statistics.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../s.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentPageIndex = 0;

  late TutorialCoachMark tutorialCoachMark;
  GlobalKey logKey = GlobalKey();
  GlobalKey statsKey = GlobalKey();
  GlobalKey gameKey = GlobalKey();
  GlobalKey playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
  }

  Future<void> _checkFirstLaunch() async {
    //final prefs = await SharedPreferences.getInstance();
    //bool isFirstLaunch = prefs.getBool('first_launch_nav') ?? true;
    bool isFirstLaunch = true;

    if (isFirstLaunch) {
      //await prefs.setBool('first_launch_nav', false);
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
      textSkip: "Skip",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onSkip: () {
        // При нажатии "Skip" переключаем на вкладку Statistics
        setState(() {
          currentPageIndex = 1;
        });
        print("Tutorial skipped, switched to Statistics");
        return true;
      },
      onFinish: () {
        print("Tutorial finished");
      },
      onClickTarget: (target) {
        print(target);
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
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1111 HELLO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "222",
                    style: TextStyle(color: Colors.amber),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "stats",
        keyTarget: statsKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "123",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "333",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      // Добавьте аналогичные TargetFocus для других элементов
    ];
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
