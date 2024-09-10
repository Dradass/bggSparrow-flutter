// TODO - Login screen, games search from net, progress bar in % or count

import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import '../db/game_things_sql.dart';
import '../db/system_table.dart';
import '../bggApi/bggApi.dart';
import '../models/system_parameters.dart';
import '../widgets/log_page_widgets.dart';
import '../widgets/camera_handler.dart';
import '../widgets/play_sender.dart';

class LoadingStatus {
  String status = "";
}

class LogScaffold extends StatefulWidget {
  const LogScaffold({super.key});

  @override
  State<LogScaffold> createState() => _LogScaffoldState();
}

class _LogScaffoldState extends State<LogScaffold> {
  bool isProgressBarVisible = false;
  LoadingStatus loadingStatus = LoadingStatus();
  var searchHistory = [];
  final SearchController searchController = SearchController();

  @override
  void initState() {
    super.initState();

    GameThingSQL.initTables().then(
      (value) {
        setState(() {
          isProgressBarVisible = true;
        });

        // Check "first time" system param
        SystemParameterSQL.selectSystemParameterByName("firstLaunch")
            .then((firstLaunchParam) {
          if (firstLaunchParam == null) {
            print("no param");
            SystemParameterSQL.addSystemParameter(
                    SystemParameter(id: 1, name: "firstLaunch", value: "1"))
                .then((value) {
              if (value == 0) print("Cant insert param");
            });
          } else {
            print("Last launch = ${firstLaunchParam.value}");
            // TODO full history loading there
            // getAllPlaysFromServer();
          }
        });

        var initializeProgress =
            initializeBggData(loadingStatus, refreshProgress);
        initializeProgress.then((value) {
          setState(() {
            isProgressBarVisible = false;
          });
        });
      },
    );
  }

  void refreshProgress(bool needShowProgressBar, String statusState) {
    print("refresh proress: ${statusState}");
    setState(() {
      isProgressBarVisible = needShowProgressBar;
      loadingStatus.status = statusState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: const Text("Log play screen"),
              centerTitle: true,
            ),
            body: SafeArea(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                        flex: 1,
                        child: Container(
                            color: Theme.of(context).colorScheme.surface,
                            width: MediaQuery.of(context).size.width,
                            child: Column(
                              children: [
                                if (isProgressBarVisible)
                                  const LinearProgressIndicator(),
                                if (isProgressBarVisible)
                                  Text("Loading. ${loadingStatus.status}")
                              ],
                            ))),
                    //ProgressBar(),
                    const ElevatedButton(
                      onPressed: (getAllPlaysFromServer),
                      child: Text("Load all data"),
                    ),
                    ElevatedButton(
                      child: const Text("del tables"),
                      onPressed: () {
                        GameThingSQL.deleteDB();
                      },
                    ),
                    // ElevatedButton(
                    //   child: const Text("create tables"),
                    //   onPressed: () {
                    //     GameThingSQL.createTable();
                    //     PlayersSQL.createTable();
                    //     LocationSQL.createTable();
                    //   },
                    // ),
                    FlexButton(PlayDatePicker(), 3),
                    FlexButton(LocationPicker(), 3),
                    FlexButton(Comments(), 4),
                    FlexButton(DurationSliderWidget(), 3),
                    FlexButton(PlaySender(searchController), 3),
                    FlexButton(PlayersPicker(), 3),
                    FlexButton(GamePicker(searchController, cameras), 3),
                    FlexButton(CameraHandler(searchController, cameras), 3),
                  ],
                )
              ],
            ))));
  }
}
