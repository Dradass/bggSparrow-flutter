import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/plays_sql.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/bgg_location.dart';
import 'package:flutter_application_1/models/bgg_play_model.dart';
import 'package:flutter_application_1/widgets/players_list.dart';
import '../db/game_things_sql.dart';
import '../db/system_table.dart';
import '../bggApi/bgg_api.dart';
import '../models/system_parameters.dart';
import '../widgets/comments.dart';
import '../widgets/duration_slider.dart';
import '../widgets/game_picker.dart';
import '../widgets/location_picker.dart';
import '../widgets/play_date_picker.dart';
import '../widgets/players_picker.dart';
import '../widgets/play_sender.dart';
import '../widgets/common.dart';
import '../widgets/calendar_month.dart';
import '../task_checker.dart';
import 'dart:developer';
import '../globals.dart';
import '../s.dart';
import 'package:provider/provider.dart';
import '../theme_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final Color initialColor = currentColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ColorPicker(
                      pickerColor: currentColor,
                      onColorChanged: (color) {
                        onColorChanged(color);
                        setState(() => currentColor = color);
                      },
                      pickerAreaHeightPercent: 1,
                      enableAlpha: false,
                      displayThumbColor: true,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () {
                    onColorChanged(initialColor);
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(S.of(context).resetAllColors),
                  onPressed: () {
                    Provider.of<ThemeManager>(context, listen: false)
                        .resetColors();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> initDataFromServer() async {
    TaskChecker().needCancel = false;

    try {
      final isConnected = await checkInternetConnection();
      if (!isConnected) {
        isLoadedGamesPlayersCountInfoNotifier.value =
            await checkAllGamesCountInfoLoaded();
        isLoadedAllGamesImagesNotifier.value =
            await checkAllGamesImagesLoaded();

        log('No internet connection');
        return;
      }

      await sendOfflinePlaysToBGG();

      setState(() {
        isProgressBarVisible = true;
        backgroundLoading = true;
      });

      final firstLaunch =
          await getOrCreateSystemParameter(1, "firstLaunch", "1");
      if (firstLaunch == "1") {
        await getAllPlaysFromServer();
        locations = await getLocalLocationsObj();
        await SystemParameterSQL.addOrEditParameter(1, "firstLaunch", "0");
      } else {
        await PlaysSQL.clearTable();
      }

      final searchMode =
          await getOrCreateSystemParameter(2, "isSearchModeOnline", "1");
      setState(() => isOnlineSearchModeDefault = searchMode == "1");

      final indicatorMode =
          await getOrCreateSystemParameter(3, "simpleIndicatorMode", "1");
      setState(() => simpleIndicatorMode = indicatorMode == "1");

      final playersListId =
          await getOrCreateSystemParameter(4, "chosenPlayersListId", "0");
      final id = int.tryParse(playersListId ?? "0") ?? 0;
      setState(() {
        defaultPlayersListId = id;
        defaultPlayersListWrapper.chosenPlayersListId = id;
        playersListWrapper.chosenPlayersListId = id;
        playersListWrapper.updatePlayersFromCustomList();
      });

      await initializeBggData(loadingStatus, context, refreshProgress);
      locations = await getLocalLocationsObj();
    } catch (e) {
      log('Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProgressBarVisible = false;
          backgroundLoading = false;
        });
      }
    }
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
                                    return Text(progress.status,
                                        key: progressBarKey);
                                  })
                          ],
                        ))),
                ElevatedButton(
                    onPressed: () {
                      TestFunction(context);
                    },
                    child: Text("Test")),
                FlexButtonSettings(
                    PlayDatePicker(),
                    IconButton(
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                        defaultPlayersListWrapper.updateCustomLists(context);
                      },
                      icon: const Icon(Icons.settings),
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
              ListTile(
                  title: Text(S.of(context).settings,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary))),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(S.of(context).logOut,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  TaskChecker().needCancel = true;

                  const storage = FlutterSecureStorage();
                  storage.write(key: userNameParamName, value: null);
                  storage.write(key: passwordParamName, value: null);

                  Navigator.pushNamed(context, '/login');
                },
              ),
              ListTile(
                leading: Icon(Icons.sync,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(S.of(context).loadAllData,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                onTap: () async {
                  await GameThingSQL.initTables();
                  if (!backgroundLoading) {
                    showSnackBar(context, S.of(context).allDataStartedLoading);
                    initDataFromServer();
                  } else {
                    showSnackBar(
                        context, S.of(context).allDataIsAlreadyStarted);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.clear,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(S.of(context).wipeAllLocalData,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                onTap: () async {
                  TaskChecker().needCancel = true;
                  await GameThingSQL.deleteDB();
                  showSnackBar(context, S.of(context).allDataWasDeleted);
                },
              ),
              Divider(),
              ListTile(
                leading: isOnlineSearchModeDefault
                    ? Icon(Icons.wifi,
                        color: Theme.of(context).colorScheme.primary)
                    : Icon(Icons.wifi_off,
                        color: Theme.of(context).colorScheme.primary),
                title: Row(
                  children: [
                    Text(
                        "${S.of(context).defaultSearchMode}: ${isOnlineSearchModeDefault ? S.of(context).online : S.of(context).offline}",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary))
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
              // ListTile(
              //   leading: Icon(
              //       simpleIndicatorMode ? Icons.circle : Icons.fingerprint,
              //       color: Theme.of(context).colorScheme.primary),
              //   title: Row(
              //     children: [
              //       Text(
              //           "${S.of(context).firstPlayerMode}: ${simpleIndicatorMode ? S.of(context).circle : S.of(context).finger}",
              //           style: TextStyle(
              //               color: Theme.of(context).colorScheme.primary))
              //     ],
              //   ),
              //   onTap: () {
              //     simpleIndicatorMode = !simpleIndicatorMode;
              //     SystemParameterSQL.updateSystemParameter(SystemParameter(
              //             id: 3,
              //             name: "simpleIndicatorMode",
              //             value: simpleIndicatorMode ? "1" : "0"))
              //         .then((onValue) => {setState(() {})});
              //   },
              // ),
              ListTile(
                title: Row(
                  children: [
                    Text("${S.of(context).currentLanguage}: ",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                    DropdownButton<Locale>(
                      value: currentLocale,
                      onChanged: (Locale? newLocale) async {
                        if (newLocale != null) {
                          S.setLocale(newLocale);

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                              'default_language', newLocale.languageCode);
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
                    Text("${S.of(context).defaultLocation}: ",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
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
                    Text("${S.of(context).defaultPlayersList}: ",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
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
              Divider(),
              ListTile(
                leading: _buildColorButton(
                  context: context,
                  color: themeManager.surfaceColor,
                  tooltip: S.of(context).selectSurfaceColor,
                ),
                title: Text(S.of(context).selectSurfaceColor,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                onTap: () {
                  _showColorPickerDialog(
                    title: S.of(context).selectSurfaceColor,
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
                  tooltip: S.of(context).selectSecondaryColor,
                ),
                title: Text(S.of(context).selectSecondaryColor,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                onTap: () {
                  _showColorPickerDialog(
                    title: S.of(context).selectSecondaryColor,
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
                  tooltip: S.of(context).selectTextColor,
                ),
                title: Text(S.of(context).selectTextColor,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                onTap: () {
                  _showColorPickerDialog(
                    title: S.of(context).selectTextColor,
                    currentColor: themeManager.textColor,
                    onColorChanged: (color) => themeManager.textColor = color,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void TestFunction(dynamic context) async {
  // Group
  DateTime? startDate = DateTime(2000);
  DateTime? endDate = DateTime(3000);
  var allPlays = await PlaysSQL.getAllPlays(startDate, endDate);

  Map<String, List<BggPlay>> groupedDates = {};
  for (var play in allPlays) {
    var playDate = DateTime.parse(play.date);
    var keyDate = DateTime(playDate.year, playDate.month, 1);
    var keyDateString = keyDate.toString();

    if (!groupedDates.containsKey(keyDateString)) {
      groupedDates[keyDateString] = [];
    }
    groupedDates[keyDateString]!.add(play);
  }

  // showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //           content: SingleChildScrollView(
  //         child: Column(
  //           children: groupedDates.entries.map((entry) {
  //             // Получаем год и месяц из ключа
  //             List<String> parts = entry.key.split('-');
  //             int year = int.parse(parts[0]);
  //             int month = int.parse(parts[1]);

  //             return Column(
  //               children: [
  //                 CalendarWidget(
  //                   year: year,
  //                   month: month,
  //                   dates:
  //                       entry.value.map((e) => DateTime.parse(e.date)).toList(),
  //                 ),
  //                 const SizedBox(height: 20), // Отступ между календарями
  //               ],
  //             );
  //           }).toList(),
  //         ),
  //       ));
  //     });
}
