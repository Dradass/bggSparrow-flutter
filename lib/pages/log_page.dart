// TODO - Login screen, games search from net

import 'package:flutter_application_1/models/bgg_location.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:image/image.dart' as imageDart;
import 'package:flutter_application_1/main.dart';
import 'package:camera/camera.dart';
import '../db/game_things_sql.dart';
import '../db/location_sql.dart';
import '../db/system_table.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../bggApi/bggApi.dart';
import 'package:flutter_pixelmatching/flutter_pixelmatching.dart';
import '../models/system_parameters.dart';

import '../widgets/duration_sliders.dart';
import '../widgets/log_page_widgets.dart';
import '../widgets/camera_handler.dart';

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
  bool? flagWarranty = false;

  DateTime? playDate = DateTime.now();
  //String loadingStatus = "";
  LoadingStatus loadingStatus = LoadingStatus();

  List<GameThing> allItems = [];
  List<GameThing> items = [];
  var searchHistory = [];
  final SearchController searchController = SearchController();

  DurationSlider durationSlider = const DurationSlider();

  var logData = {
    "playdate": "2024-03-15",
    "comments": "#bggSparrow",
    "length": 60,
    "twitter": "false",
    "minutes": 60,
    "location": "Home",
    "objectid": "158899",
    "hours": 0,
    "quantity": "1",
    "action": "save",
    "date": "2024-02-28T05:00:00.000Z",
    "players": [],
    "objecttype": "thing",
    "ajax": 1
  };

  Map<String, bool> values = {
    'foo': true,
    'bar': false,
  };

  void queryListener() {
    search(searchController.text);
  }

  void search(String query) {
    if (query.isEmpty) {
      setState(() {
        items = allItems;
      });
    } else {
      setState(() {
        items = allItems
            .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    Comments().commentsController.dispose();
    super.dispose();

    searchController.removeListener(queryListener);
    searchController.dispose();
  }

  void setLocationButtonName() {
    var defaultLocationRes = fillLocationName();
    defaultLocationRes.then((defaultLocationValue) {
      if (defaultLocationValue != null) {
        setState(() {
          LocationPicker().selectedLocation = defaultLocationValue.name;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(queryListener);

    searchController.text = "Select game";

    GameThingSQL.initTables().then(
      (value) {
        setState(() {
          isProgressBarVisible = true;
        });
        setLocationButtonName();

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

        var initializeProgress = initializeBggData(loadingStatus);
        initializeProgress.then((value) {
          setState(() {
            isProgressBarVisible = false;
          });
        });
      },
    );
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
                            // height: isProgressBarVisible
                            //     ? MediaQuery.of(context).size.height
                            //     : MediaQuery.of(context).size.height,
                            child: Column(
                              children: [
                                if (isProgressBarVisible)
                                  const LinearProgressIndicator(),
                                if (isProgressBarVisible)
                                  Text("Loading. ${loadingStatus.status}")
                              ],
                            ))),
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
                    Flexible(
                        flex: 3,
                        child: SizedBox(
                            //color: Colors.green,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (CameraHandler(searchController, cameras)
                                          .recognizedGameId <=
                                      0) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'No game was chosen to log play'),
                                    ));
                                  }
                                  List<Map> bggPlayers = [];
                                  for (var player in PlayersPicker()
                                      .players
                                      .where((element) =>
                                          element['isChecked'] == true)) {
                                    bggPlayers.add({
                                      'username': player['username'],
                                      'userid': player['userid'],
                                      'name': player['name'],
                                      'win': player['win'] ? 1 : 0
                                    });
                                  }
                                  final nowData = DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now());
                                  logData['players'] = bggPlayers;
                                  logData['objectid'] =
                                      CameraHandler(searchController, cameras)
                                          .recognizedGameId;
                                  logData['length'] = DurationSliderWidget()
                                      .durationCurrentValue;
                                  logData['playdate'] = DateFormat('yyyy-MM-dd')
                                      .format(PlayDatePicker().playDate);
                                  logData['date'] =
                                      "${DateFormat('yyyy-MM-dd').format(PlayDatePicker().playDate)}T05:00:00.000Z";
                                  logData['comments'] =
                                      Comments().commentsController.text;

                                  var chosenLocation =
                                      await LocationSQL.selectLocationByName(
                                          LocationPicker().selectedLocation);
                                  print(chosenLocation);
                                  logData['location'] = chosenLocation != null
                                      ? chosenLocation.name
                                      : "";
                                  String stringData = json.encode(logData);
                                  print(stringData);
                                  await sendLogRequest(stringData);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Request was sent'),
                                  ));
                                },
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                            side: BorderSide(
                                                color: Colors.black12)))),
                                label: const Text("Log play"),
                                icon: const Icon(Icons.send_and_archive)))),
                    FlexButton(PlayersPicker(), 3),
                    Flexible(
                        flex: 3,
                        child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                    padding: EdgeInsets.only(right: 0),
                                    width:
                                        MediaQuery.of(context).size.width * 0.2,
                                    child: CameraHandler(searchController,
                                                        cameras)
                                                    .recognizedGame !=
                                                null &&
                                            CameraHandler(searchController,
                                                        cameras)
                                                    .recognizedGame!
                                                    .thumbBinary !=
                                                null
                                        ? Image.memory(base64Decode(
                                            CameraHandler(
                                                    searchController, cameras)
                                                .recognizedGame!
                                                .thumbBinary!))
                                        : Icon(Icons.image)),
                                Container(
                                  padding: EdgeInsets.only(right: 0),
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  height: MediaQuery.of(context).size.height,
                                  // height: MediaQuery.of(context).size.height *
                                  //     0.5,
                                  child: SearchAnchor(
                                      searchController: searchController,
                                      builder: (context, searchController) {
                                        return SearchBar(
                                          shape: MaterialStateProperty.all(
                                              const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  side: BorderSide(
                                                      color: Colors.black12))),
                                          controller: searchController,
                                          leading: IconButton(
                                              onPressed: () {},
                                              icon: Icon(Icons.search)),
                                          onTap: () async {
                                            var actualGames = await GameThingSQL
                                                .getAllGames();
                                            allItems = actualGames ?? [];
                                            searchController.text = "";
                                            searchController.openView();
                                          },
                                          onChanged: (_) {
                                            searchController.openView();
                                          },
                                          padding:
                                              const MaterialStatePropertyAll<
                                                      EdgeInsets>(
                                                  EdgeInsets.symmetric(
                                                      horizontal: 16.0)),
                                        );
                                      },
                                      suggestionsBuilder:
                                          (context, searchController) {
                                        return List<Column>.generate(
                                            items.isEmpty
                                                ? allItems.length
                                                : items.length, (int index) {
                                          final item = items.isEmpty
                                              ? allItems[index]
                                              : items[index];
                                          return Column(children: [
                                            ListTile(
                                                title: Text(item.name),
                                                leading: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                        maxHeight:
                                                            MediaQuery.of(context)
                                                                .size
                                                                .height,
                                                        maxWidth: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            10),
                                                    child: item.thumbBinary !=
                                                            null
                                                        ? Image.memory(
                                                            base64Decode(item
                                                                .thumbBinary!))
                                                        : Icon(
                                                            Icons.broken_image)),
                                                onTap: () {
                                                  setState(() {
                                                    searchController
                                                        .closeView(item.name);
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    CameraHandler(
                                                                searchController,
                                                                cameras)
                                                            .recognizedGameId =
                                                        item.id;
                                                    CameraHandler(
                                                            searchController,
                                                            cameras)
                                                        .recognizedGame = item;
                                                  });
                                                }),
                                            const Divider(
                                              height: 0,
                                              color: Colors.black12,
                                            ),
                                          ]);
                                        });
                                      }),
                                ),
                              ],
                            ))),
                    FlexButton(CameraHandler(searchController, cameras), 3),
                  ],
                )
              ],
            ))));
  }
}

Future<int> getSimilarGameID(
    Uint8List bytes, List<GameThing> getGamesWithThumb) async {
  final matching = PixelMatching();
  await matching.initialize(image: bytes);

  var bestSimilarity = 0.0;
  var bestSimilarGameID = 0;
  if (matching.isInitialized) {
    for (final gameImage in getGamesWithThumb) {
      if (gameImage.thumbBinary == null) continue;
      final binaryImage = base64Decode(gameImage.thumbBinary!);

      final similarity = await matching.similarity(binaryImage);
      print(
          "game = ${gameImage.name}, id = ${gameImage.id}, similarity = $similarity");
      if (similarity > bestSimilarity) {
        bestSimilarGameID = gameImage.id;
        bestSimilarity = similarity;
      }
    }
    //bestSimilarity = 0;
    print("bestSimilarGameID = $bestSimilarGameID");
    matching.dispose();
    return bestSimilarGameID;
  }
  matching.dispose();
  return bestSimilarGameID;
}

Future<int> sendLogRequest(String logData) async {
  print("-----start sending");
  dynamic bodyLogin = json.encode({
    'credentials': {'username': 'dradass', 'password': '1414141414'}
  });

  http
      .post(Uri.parse("https://boardgamegeek.com/login/api/v1"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: bodyLogin)
      .then((response) {
    String sessionCookie = '';
    for (final cookie in response.headers['set-cookie']!.split(';')) {
      if (cookie.startsWith('bggusername')) {
        sessionCookie += '${cookie.isNotEmpty ? ' ' : ''}$cookie;';
        continue;
      }
      var idx = cookie.indexOf('bggpassword=');
      if (idx != -1) {
        sessionCookie +=
            '${cookie.isNotEmpty ? ' ' : ''}bggpassword=${cookie.substring(idx + 12)};';
        continue;
      }
      idx = cookie.indexOf('SessionID=');
      if (idx != -1) {
        sessionCookie +=
            '${cookie.isNotEmpty ? ' ' : ''}SessionID=${cookie.substring(idx + 10)};';
        continue;
      }
    }

    http
        .post(Uri.parse("https://boardgamegeek.com/geekplay.php"),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'cookie': sessionCookie,
            },
            body: logData)
        .then((response2) {});
  });

  return 1;
}
