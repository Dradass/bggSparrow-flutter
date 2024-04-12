// TODO - Random game chooser

import 'package:flutter_application_1/models/bgg_location.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:image/image.dart' as imageDart;
import 'package:flutter_application_1/main.dart';
import 'package:camera/camera.dart';
import '../db/game_things_sql.dart';
import '../db/players_sql.dart';
import '../db/location_sql.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../bggApi/bggApi.dart';
import 'package:flutter_pixelmatching/flutter_pixelmatching.dart';

import '../widgets/duration_sliders.dart';

class LogScaffold extends StatefulWidget {
  const LogScaffold({super.key});

  @override
  State<LogScaffold> createState() => _LogScaffoldState();
}

class _LogScaffoldState extends State<LogScaffold> {
  bool isProgressBarVisible = false;
  late CameraController _controller;
  var recognizedImage = "No image";
  bool? flagWarranty = false;
  var recognizedGameId = 0;
  GameThing? recognizedGame;
  double durationCurrentValue = 60;
  Uint8List imageFromCamera = Uint8List.fromList(List.empty());
  List<Map> players = [];
  List<Map> locations = [];
  final _focusNode = FocusNode();

  List<GameThing> allItems = []; // List.generate(50, (index) => 'item $index');
  List<GameThing> items = [];
  var searchHistory = [];
  //final TextEditingController searchController = TextEditingController();
  final SearchController searchController = SearchController();
  // String defaultLocation = LocationSQL.getDefaultLocationSync() != null
  //     ? LocationSQL.getDefaultLocationSync()!.name
  //     : "";
  String selectedLocation = "";
  final TextEditingController commentsController =
      TextEditingController(text: "#bggSparrow");
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

  Future<int?> TakePhoto() async {
    var result = 0;

    print("---------------Got photo");
    try {
      var capturedImage = await _controller.takePicture();
      var bytes = await capturedImage.readAsBytes();

      imageDart.Image? img = imageDart.decodeImage(bytes);
      if (img == null) return 0;

      //print("Height = ${WidgetsBinding.instance.window.physicalSize.height}");
      var ratio = img.height / 150;
      imageDart.Image resizedImg = imageDart.copyResize(img,
          width: (img.width / ratio).round(),
          height: (img.height / ratio).round());

      var imgBytes = imageDart.encodeJpg(resizedImg);

      var getGamesWithThumb = await GameThingSQL.getAllGames();

      setState(() {
        imageFromCamera = imgBytes;
      });

      if (getGamesWithThumb == null) return 0;
      print("recognizedImage = $recognizedImage");
      Map<int, double> compareResults = {};

      int bestGameID = 0;
      bestGameID = await getSimilarGameID(imgBytes, getGamesWithThumb);
      // bestGameID = await Isolate.run(() async {
      //   return getSimilarGameID(imgBytes, getGamesWithThumb);
      // });
      print(bestGameID);
      result = bestGameID;
      return result;
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
      return 0;
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    commentsController.dispose();
    super.dispose();

    searchController.removeListener(queryListener);
    searchController.dispose();
  }

  void setLocationButtonName() {
    var defaultLocationRes = fillLocationName();
    defaultLocationRes.then((defaultLocationValue) {
      if (defaultLocationValue != null) {
        setState(() {
          selectedLocation = defaultLocationValue.name;
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
        var initializeProgress = initializeBggData();
        initializeProgress.then((value) {
          setState(() {
            isProgressBarVisible = false;
          });
        });
      },
    );

    _controller = CameraController(cameras.first, ResolutionPreset.max,
        enableAudio: false);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print("access was denied");
            break;
          default:
            print(e.description);
            break;
        }
      }
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
                        child: SizedBox(
                            //color: Colors.tealAccent,
                            width: MediaQuery.of(context).size.width,
                            height: isProgressBarVisible
                                ? MediaQuery.of(context).size.height
                                : 0,
                            child: Column(
                              children: [
                                if (isProgressBarVisible)
                                  const LinearProgressIndicator(),
                                if (isProgressBarVisible)
                                  const Text("Loading BGG data")
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
                    // Flexible(
                    //     flex: 1,
                    //     child: SizedBox(
                    //       //color: Colors.tealAccent,
                    //       width: MediaQuery.of(context).size.width,
                    //       height: MediaQuery.of(context).size.height,
                    //       child: Center(
                    //           child: Text(recognizedImage,
                    //               textAlign: TextAlign.center)),
                    //     )),
                    // Flexible(
                    //     flex: 3,
                    //     child: SizedBox(
                    //         //color: Colors.lime,
                    //         width: MediaQuery.of(context).size.width,
                    //         //child: FittedBox(
                    //         child: imageFromCamera.isNotEmpty
                    //             ? Image.memory(
                    //                 imageFromCamera,
                    //                 height: MediaQuery.of(context).size.height,
                    //               )
                    //             : //Image.asset('assets/not_bad.png')
                    //             Icon(Icons.image)
                    //         //)
                    //         )),
                    Flexible(
                        flex: 3,
                        child: SizedBox(
                            //color: Colors.tealAccent,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (locations.isEmpty) {
                                    locations = await getLocalLocations();
                                  }
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext) {
                                        return StatefulBuilder(
                                            builder: (context, setState) {
                                          return AlertDialog(
                                              //insetPadding: EdgeInsets.zero,
                                              title:
                                                  const Text("Your locations"),
                                              content: SingleChildScrollView(
                                                  child: Column(
                                                      children: locations
                                                          .map((location) {
                                                return ElevatedButton(
                                                  child: Row(children: [
                                                    ChoiceChip(
                                                        label: const Text(
                                                            "Default"),
                                                        selected: location[
                                                                'isDefault'] ==
                                                            1,
                                                        onSelected:
                                                            (bool value) {
                                                          setState(() {
                                                            for (var location
                                                                in locations) {
                                                              location[
                                                                  'isDefault'] = 0;
                                                            }

                                                            location[
                                                                    'isDefault'] =
                                                                value ? 1 : 0;
                                                            print(value);
                                                            var locationObject =
                                                                Location(
                                                                    id: location[
                                                                        'id'],
                                                                    name: location[
                                                                        'name'],
                                                                    isDefault:
                                                                        value
                                                                            ? 1
                                                                            : 0);
                                                            LocationSQL
                                                                .updateDefaultLocation(
                                                                    locationObject);
                                                          });
                                                        }),
                                                    Expanded(
                                                        child: Text(
                                                      location['name'],
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ))
                                                  ]),
                                                  onPressed: () {
                                                    Navigator.of(context,
                                                            rootNavigator: true)
                                                        .pop();
                                                    for (var checkedLocation
                                                        in locations) {
                                                      checkedLocation[
                                                          'isChecked'] = false;
                                                    }
                                                    location['isChecked'] =
                                                        true;
                                                    selectedLocation =
                                                        location['name'];
                                                  },
                                                );
                                              }).toList())));
                                        });
                                      }).then((value) {
                                    setState(() {
                                      //defaultLocation = '111';
                                    });
                                  });
                                },
                                style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                            side: BorderSide(
                                                color: Colors.black12)))),
                                label: Text(selectedLocation.isEmpty
                                    ? "Select location"
                                    : selectedLocation),
                                icon: const Icon(Icons.home)))),
                    Flexible(
                        flex: 4,
                        child: SizedBox(
                            //color: Colors.green,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: TextField(
                              focusNode: _focusNode,
                              controller: commentsController,
                              keyboardType: TextInputType.multiline,
                              maxLines: 5,
                              decoration: InputDecoration(
                                  //prefixIcon: Icon(Icons.search),
                                  suffixIcon: IconButton(
                                      onPressed: commentsController.clear,
                                      icon: const Icon(Icons.clear)),
                                  labelText: 'Comments',
                                  hintText: 'Enter your comments',
                                  //helperText: 'supporting text',
                                  //border: OutlineInputBorder(),
                                  border: UnderlineInputBorder()),
                            ))),
                    Flexible(
                        flex: 3,
                        child: SizedBox(
                            //color: Colors.blueAccent,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: Column(
                              children: [
                                //const Text("Duration"),
                                Slider(
                                  value: durationCurrentValue,
                                  max: 500,
                                  divisions: 50,
                                  label:
                                      durationCurrentValue.round().toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      durationCurrentValue = value;
                                    });
                                  },
                                ),

                                Text("Duration")
                              ],
                            ))),
                    Flexible(
                        flex: 3,
                        child: SizedBox(
                            //color: Colors.green,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (recognizedGameId <= 0) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'No game was chosen to log play'),
                                    ));
                                  }
                                  List<Map> bggPlayers = [];
                                  for (var player in players.where((element) =>
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
                                  logData['objectid'] = recognizedGameId;
                                  logData['length'] = durationCurrentValue;
                                  logData['playdate'] = nowData;
                                  logData['date'] = "${nowData}T05:00:00.000Z";
                                  logData['comments'] = commentsController.text;

                                  var chosenLocation =
                                      await LocationSQL.selectLocationByName(
                                          selectedLocation);
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
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                            side: BorderSide(
                                                color: Colors.black12)))),
                                label: const Text("Log play"),
                                icon: const Icon(Icons.send_and_archive)))),
                    Flexible(
                        flex: 3,
                        child: SizedBox(
                            //color: Colors.tealAccent,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (players.isEmpty) {
                                    players = await getLocalPlayers();
                                  }
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext) {
                                        return StatefulBuilder(
                                            builder: (context, setState) {
                                          return AlertDialog(
                                              //insetPadding: EdgeInsets.zero,
                                              title: const Text("Your friends"),
                                              content: SingleChildScrollView(
                                                  child: Column(
                                                      children:
                                                          players.map((player) {
                                                return CheckboxListTile(
                                                  title: Row(children: [
                                                    ChoiceChip(
                                                        label:
                                                            const Text("Win?"),
                                                        selected: player['win'],
                                                        onSelected:
                                                            (bool? value) {
                                                          setState(() {
                                                            player['win'] =
                                                                value;
                                                          });
                                                        }),
                                                    Expanded(
                                                        child: Text(
                                                      player['name'],
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ))
                                                  ]),
                                                  value: player['isChecked'],
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      player['isChecked'] =
                                                          value;
                                                    });
                                                  },
                                                );
                                              }).toList())));
                                        });
                                      });
                                },
                                style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                            side: BorderSide(
                                                color: Colors.black12)))),
                                label: const Text("Select players"),
                                icon: const Icon(Icons.people)))),
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
                                    child: recognizedGame != null &&
                                            recognizedGame!.thumbBinary != null
                                        ? Image.memory(base64Decode(
                                            recognizedGame!.thumbBinary!))
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
                                                    recognizedGameId = item.id;
                                                    recognizedGame = item;
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
                    Flexible(
                        flex: 3,
                        child: SizedBox(
                            //color: Colors.tealAccent,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext) {
                                        return AlertDialog(
                                          title: const Text('Take photo'),
                                          content: Column(children: [
                                            //Text(recognizedImage),
                                            SizedBox(
                                              height: 300,
                                              child: CameraPreview(_controller),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                recognizedGameId = 0;
                                                Navigator.of(context,
                                                        rootNavigator: true)
                                                    .pop();
                                                setState(() {
                                                  searchController.text =
                                                      "Game recognizing";
                                                });
                                                var gameId = await TakePhoto();
                                                var recognizedGameName =
                                                    "Cant find similar game";

                                                if (gameId != null) {
                                                  recognizedGame =
                                                      await GameThingSQL
                                                          .selectGameByID(
                                                              gameId);
                                                  if (recognizedGame != null) {
                                                    recognizedGameId =
                                                        recognizedGame!.id;

                                                    recognizedGameName =
                                                        recognizedGame!.name;
                                                  }
                                                }

                                                setState(() {
                                                  searchController.text =
                                                      recognizedGameName;
                                                });
                                              },
                                              child: const Text('Take a photo'),
                                            )
                                          ]),
                                        );
                                      });
                                },
                                style: ButtonStyle(
                                    // backgroundColor: MaterialStateProperty.all(
                                    //     Theme.of(context).primaryColor),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                            side: BorderSide(
                                                color: Colors.black12)))),
                                label: const Text("Recognize game"),
                                icon: const Icon(Icons.photo_camera))))
                  ],
                )
              ],
            ))));
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
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

Future<int?> testIsolate(Uint8List bytes) async {
  int result = 0;
  result = 25;
  return result;
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
