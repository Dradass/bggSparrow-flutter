import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/bgg_location.dart';
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
import '../s.dart';
import 'package:provider/provider.dart';
import '../theme_manager.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../db/location_sql.dart';

int swipeDelta = 30;

class LoadingStatus {
  String status = "";
}

class DownloadProgress {
  final String status;

  DownloadProgress({required this.status});
}

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  List<Location> locations = [];
  Location? chosenLocation;

  final ValueNotifier<DownloadProgress> progressNotifier =
      ValueNotifier(DownloadProgress(status: ""));

  @override
  void initState() {
    super.initState();
    getLocalLocationsObj().then((locationsResult) {
      if (locationsResult.isNotEmpty) {
        locations = locationsResult;
      }
    });

    if (!backgroundLoading) {
      initDataFromServer();
    }
  }

  // void _changeColor(Color color) async {
  //   // Обновляем глобальный цвет
  //   main_app.secondaryColorNotifier.value = color;

  //   // Сохраняем цвет в SharedPreferences
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setInt('secondaryColor', color.value);
  // }
  Widget _buildColorButton({
    required BuildContext context,
    required Color color,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog({
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    Color tempColor = currentColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              children: [
                ColorPicker(
                  pickerColor: currentColor,
                  onColorChanged: (color) => tempColor = color,
                  pickerAreaHeightPercent: 1,
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    onColorChanged(tempColor);
                    Navigator.of(context).pop();
                  },
                  child: Text("Apply"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Reset all colors"),
              onPressed: () {
                Provider.of<ThemeManager>(context, listen: false).resetColors();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void initDataFromServer() {
    checkInternetConnection().then((isConnected) => {
          if (!isConnected)
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
                  var initializeProgress = initializeBggData(
                      loadingStatus, context, refreshProgress);
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
    progressNotifier.value = DownloadProgress(status: statusState);
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
    final themeManager = Provider.of<ThemeManager>(context);
    final currentLocale = S.currentLocale;
    defaultPlayersListWrapper.updateCustomLists(context);
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > swipeDelta) {
          if (!backgroundLoading) {
            initDataFromServer();
          }
        }
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
                              ValueListenableBuilder<DownloadProgress>(
                                  valueListenable: progressNotifier,
                                  builder: (_, progress, __) {
                                    return Text(progress.status);
                                  })
                          ],
                        ))),
                FlexButtonSettings(
                    PlayDatePicker(),
                    IconButton(
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                          defaultPlayersListWrapper.updateCustomLists(context);
                        },
                        icon: const Icon(Icons.settings)),
                    3),
                FlexButton(LocationPicker(), 3),
                FlexButton(Comments(), 5),
                FlexButton(DurationSliderWidget(), 3),
                FlexButton(PlaySender(searchController, playersListWrapper), 3),
                FlexButton(PlayersPicker(playersListWrapper), 3),
                FlexButton(
                    GamePicker(
                        searchController..text = S.of(context).selectGame,
                        cameras,
                        _imagewidget),
                    3),
              ],
            )
          ],
        )),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const ListTile(title: Text('')),
              ListTile(title: Text(S.of(context).settings)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(S.of(context).logOut),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  TaskChecker().needCancel = true;
                  Navigator.pushNamed(context, '/login');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: Text(S.of(context).loadAllData),
                onTap: () {
                  GameThingSQL.initTables();
                  if (!backgroundLoading) {
                    initDataFromServer();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: Text(S.of(context).wipeAllLocalData),
                onTap: () {
                  TaskChecker().needCancel = true;
                  GameThingSQL.deleteDB();
                },
              ),
              ListTile(
                leading: _buildColorButton(
                  context: context,
                  color: themeManager.surfaceColor,
                  tooltip: "Pick surface color",
                ),
                title: Text("Pick surface color"),
                onTap: () {
                  _showColorPickerDialog(
                    title: "Pick surface color",
                    currentColor: themeManager.surfaceColor,
                    onColorChanged: (color) =>
                        themeManager.surfaceColor = color,
                  );
                },
              ),
              ListTile(
                leading: _buildColorButton(
                  context: context,
                  color: themeManager.secondaryColor,
                  tooltip: "Pick secondary color",
                ),
                title: Text("Pick secondary color"),
                onTap: () {
                  _showColorPickerDialog(
                    title: "Pick secondary color",
                    currentColor: themeManager.secondaryColor,
                    onColorChanged: (color) =>
                        themeManager.secondaryColor = color,
                  );
                },
              ),
              ListTile(
                leading: _buildColorButton(
                  context: context,
                  color: themeManager.textColor,
                  tooltip: "Pick text color",
                ),
                title: Text("Pick text color"),
                onTap: () {
                  _showColorPickerDialog(
                    title: "Pick text color",
                    currentColor: themeManager.textColor,
                    onColorChanged: (color) => themeManager.textColor = color,
                  );
                },
              ),
              ListTile(
                leading: isOnlineSearchModeDefault
                    ? Icon(Icons.wifi)
                    : Icon(Icons.wifi_off),
                title: Row(
                  children: [
                    Text(
                        "${S.of(context).defaultSearchMode}: ${isOnlineSearchModeDefault ? S.of(context).online : S.of(context).offline}")
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
                        "${S.of(context).firstPlayerMode}: ${simpleIndicatorMode ? S.of(context).circle : S.of(context).finger}")
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
                    Text("${S.of(context).currentLanguage}: "),
                    DropdownButton<Locale>(
                      value: currentLocale,
                      onChanged: (Locale? newLocale) {
                        if (newLocale != null) {
                          S.setLocale(newLocale);
                        }
                      },
                      items: S.supportedLanguages
                          .map((toElement) => Locale(toElement['code']))
                          .map((Locale locale) {
                        return DropdownMenuItem<Locale>(
                          value: locale,
                          child: Row(
                            children: [
                              Text(
                                S.supportedLanguages.firstWhere(
                                      (element) =>
                                          Locale(element['code']) == locale,
                                    )['nativeName'] ??
                                    'English',
                                style: TextStyle(
                                  fontWeight: currentLocale == locale
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Row(
                  children: [
                    Text("${S.of(context).defaultLocation}: "),
                    DropdownButton<Location>(
                      value: chosenLocation ??
                          (locations.isNotEmpty &&
                                  locations.any((x) => x.isDefault == 1)
                              ? locations.where((x) => x.isDefault == 1).first
                              : null),
                      onChanged: (Location? changedLocation) {
                        if (changedLocation != null) {
                          var locationObject = Location(
                              id: changedLocation.id,
                              name: changedLocation.name,
                              isDefault: 1);
                          LocationSQL.updateDefaultLocation(locationObject)
                              .then((onValue) {
                            chosenLocation = changedLocation;
                            setState(() {});
                          });
                        }
                      },
                      items: locations.map((location) {
                        return DropdownMenuItem<Location>(
                          value: location,
                          child: Row(
                            children: [
                              Text(
                                location.name,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Row(
                  children: [
                    Text("${S.of(context).defaultPlayersList}: "),
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
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
