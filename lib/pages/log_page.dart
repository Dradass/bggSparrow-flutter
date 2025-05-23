import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/players_list.dart';
import '../db/game_things_sql.dart';
import '../db/system_table.dart';
import '../bggApi/bgg_api.dart';
import '../models/system_parameters.dart';
import '../widgets/log_page_widgets.dart';
import '../widgets/play_sender.dart';
import '../widgets/common.dart';
import '../task_checker.dart';
import 'dart:developer';
import '../globals.dart';

class LoadingStatus {
  String status = "";
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  PlayersListWrapper playersListWrapper = PlayersListWrapper();
  var hasInternetConnection = false;
  String binaryImageData = "";
  bool isOnlineSearchModeDefault = true;
  final Image _imagewidget = Image.asset('assets/no_image.png');
  PlayersListWrapper defaultPlayersListWrapper = PlayersListWrapper();

  @override
  void initState() {
    super.initState();

    checkInternetConnection().then((isConnected) => {
          if (!isConnected)
            //{showSnackBar(context, 'No internet connection')}
            log('No internet connection')
          else
            {
              sendOfflinePlaysToBGG(),
              GameThingSQL.initTables().then(
                (value) {
                  setState(() {
                    isProgressBarVisible = true;
                    backgroundLoading = true;
                  });

                  // Check "first time" system param
                  getOrCreateSystemParameter(1, "firstLaunch", "1")
                      .then((paramValue) {
                    if (paramValue == "1") {
                      getAllPlaysFromServer();
                      SystemParameterSQL.addOrEditParameter(
                          1, "firstLaunch", "0");
                    }
                  });

                  // Check "search mode" system param
                  getOrCreateSystemParameter(2, "isSearchModeOnline", "1")
                      .then((paramValue) {
                    isOnlineSearchModeDefault = paramValue == "1";
                  });

                  // Check "first player mode" system param
                  getOrCreateSystemParameter(3, "simpleIndicatorMode", "1")
                      .then((paramValue) {
                    simpleIndicatorMode = paramValue == "1";
                  });

                  // Check "Default players list" system param
                  getOrCreateSystemParameter(4, "chosenPlayersListId", "0")
                      .then((paramValue) {
                    defaultPlayersListId = int.parse(paramValue ?? "0");
                    defaultPlayersListWrapper.chosenPlayersListId =
                        defaultPlayersListId;
                    playersListWrapper.chosenPlayersListId =
                        defaultPlayersListId;
                    playersListWrapper.updatePlayersFromCustomList();
                  });

                  var initializeProgress =
                      initializeBggData(loadingStatus, refreshProgress);
                  initializeProgress.then((value) {
                    setState(() {
                      isProgressBarVisible = false;
                      backgroundLoading = false;
                    });
                  });
                },
              )
            }
        });
  }

  void refreshProgress(bool needShowProgressBar, String statusState) {
    log("refresh proress: $statusState");
    setState(() {
      isProgressBarVisible = needShowProgressBar;
      loadingStatus.status = statusState;
    });
  }

  Future<String?> getOrCreateSystemParameter(
      int paramId, String paramName, String defaultValue) async {
    var paramValue =
        await SystemParameterSQL.selectSystemParameterById(paramId);
    if (paramValue == null) {
      var addingResult = await SystemParameterSQL.addSystemParameter(
          SystemParameter(id: paramId, name: paramName, value: defaultValue));
      if (addingResult == 0) {
        log("Cant insert param $paramName");
      }
      return defaultValue;
    } else {
      return paramValue.value ?? defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    defaultPlayersListWrapper.updateCustomLists();
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: _scaffoldKey,
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
                              LinearProgressIndicator(
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                            if (isProgressBarVisible)
                              Text(loadingStatus.status,
                                  overflow: TextOverflow.ellipsis)
                          ],
                        ))),
                FlexButtonSettings(
                    PlayDatePicker(),
                    IconButton(
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                          defaultPlayersListWrapper.updateCustomLists();
                        },
                        icon: const Icon(Icons.settings)),
                    3),
                FlexButton(LocationPicker(), 3),
                FlexButton(Comments(), 5),
                FlexButton(DurationSliderWidget(), 3),
                FlexButton(PlaySender(searchController, playersListWrapper), 3),
                FlexButton(PlayersPicker(playersListWrapper), 3),
                FlexButton(
                    GamePicker(searchController, cameras, _imagewidget), 3),
              ],
            )
          ],
        )),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const ListTile(title: Text('')),
              const ListTile(title: Text('Settings')),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  TaskChecker().needCancel = true;
                  Navigator.pushNamed(context, '/login');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Load all data'),
                onTap: () {
                  GameThingSQL.initTables();
                  getAllPlaysFromServer();
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Wipe all data'),
                onTap: () {
                  GameThingSQL.deleteDB();
                },
              ),
              ListTile(
                leading: const Icon(Icons.wifi),
                title: Row(
                  children: [
                    Text(
                        "Default search mode: ${isOnlineSearchModeDefault ? 'Online' : 'Offline'}")
                  ],
                ),
                onTap: () {
                  isOnlineSearchModeDefault = !isOnlineSearchModeDefault;
                  SystemParameterSQL.updateSystemParameter(SystemParameter(
                          id: 2,
                          name: "isSearchModeOnline",
                          value: isOnlineSearchModeDefault ? "1" : "0"))
                      .then((onValue) => {setState(() {})});
                },
              ),
              ListTile(
                leading: Icon(
                    simpleIndicatorMode ? Icons.circle : Icons.fingerprint),
                title: Row(
                  children: [
                    Text(
                        "First player mode: ${simpleIndicatorMode ? 'Circle' : 'Finger'}")
                  ],
                ),
                onTap: () {
                  simpleIndicatorMode = !simpleIndicatorMode;
                  SystemParameterSQL.updateSystemParameter(SystemParameter(
                          id: 3,
                          name: "simpleIndicatorMode",
                          value: simpleIndicatorMode ? "1" : "0"))
                      .then((onValue) => {setState(() {})});
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Text("Default players list: "),
                    ChooseListDropdown(
                        playersListWrapper: defaultPlayersListWrapper,
                        parentStateUpdate: () => {
                              SystemParameterSQL.addOrEditParameter(
                                  4,
                                  "chosenPlayersListId",
                                  defaultPlayersListWrapper.chosenPlayersListId
                                      .toString()),
                              setState(() {})
                            }),
                  ],
                ),
                onTap: null
                // simpleIndicatorMode = !simpleIndicatorMode;
                // SystemParameterSQL.updateSystemParameter(SystemParameter(
                //         id: 3,
                //         name: "simpleIndicatorMode",
                //         value: simpleIndicatorMode ? "1" : "0"))
                //     .then((onValue) => {setState(() {})});
                ,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
