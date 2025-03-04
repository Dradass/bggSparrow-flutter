import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import '../db/game_things_sql.dart';
import '../db/system_table.dart';
import '../bggApi/bggApi.dart';
import '../models/system_parameters.dart';
import '../widgets/log_page_widgets.dart';
import '../widgets/play_sender.dart';
import '../widgets/common.dart';
import '../task_checker.dart';

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
  var hasInternetConnection = false;
  String binaryImageData = "";
  bool isOnlineSearchModeDefault = true;
  final Image _imagewidget = Image.asset('assets/no_image.png');

  @override
  void initState() {
    super.initState();

    checkInternetConnection().then((isConnected) => {
          if (!isConnected)
            {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No internet connection!')))
            }
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
                  SystemParameterSQL.selectSystemParameterById(1)
                      .then((firstLaunchParam) {
                    if (firstLaunchParam == null) {
                      SystemParameterSQL.addSystemParameter(SystemParameter(
                              id: 1, name: "firstLaunch", value: "1"))
                          .then((value) {
                        if (value == 0) print("Cant insert param");
                      });
                      getAllPlaysFromServer();
                    } else {
                      print("Last launch = ${firstLaunchParam.value}");
                    }
                  });

                  // Check "search mode" system param
                  SystemParameterSQL.selectSystemParameterById(2)
                      .then((isSearchModeOnline) {
                    if (isSearchModeOnline == null) {
                      SystemParameterSQL.addSystemParameter(SystemParameter(
                              id: 2, name: "isSearchModeOnline", value: "1"))
                          .then((value) {
                        if (value == 0) print("Cant insert param");
                      });
                    } else {
                      isOnlineSearchModeDefault =
                          isSearchModeOnline.value == "1";
                      print("isSearchModeOnline = ${isSearchModeOnline.value}");
                    }
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
    print("refresh proress: $statusState");
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
        key: _scaffoldKey,
        // resizeToAvoidBottomInset: false,
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
                              Text("Loading. ${loadingStatus.status}",
                                  overflow: TextOverflow.ellipsis)
                          ],
                        ))),
                FlexButtonSettings(
                    PlayDatePicker(),
                    IconButton(
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        icon: Icon(Icons.settings)),
                    3),
                FlexButton(LocationPicker(), 3),
                FlexButton(Comments(), 5),
                FlexButton(DurationSliderWidget(), 3),
                FlexButton(PlaySender(searchController, _imagewidget), 3),
                FlexButton(PlayersPicker(), 3),
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
              ListTile(
                title: const Text(''),
              ),
              ListTile(
                title: const Text('Settings'),
              ),
              Divider(),
              ListTile(
                leading: Icon(
                  Icons.logout,
                ),
                title: const Text('Log out'),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  TaskChecker().needCancel = true;
                  Navigator.pushNamed(context, '/login');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.sync,
                ),
                title: const Text('Load all data'),
                onTap: () {
                  GameThingSQL.initTables();
                  getAllPlaysFromServer();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.clear,
                ),
                title: const Text('Wipe all data'),
                onTap: () {
                  GameThingSQL.deleteDB();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.wifi,
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
