// TODO - Random game chooser

import 'dart:io';
import 'dart:isolate';

import 'package:flutter_application_1/models/bgg_location.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:image/image.dart' as imageDart;
import 'package:flutter_application_1/main.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import '../db/game_things_sql.dart';
import '../db/players_sql.dart';
import '../db/location_sql.dart';
import '../models/game_thing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../bggApi/bggApi.dart';
import 'package:collection/collection.dart';
import 'package:flutter_pixelmatching/flutter_pixelmatching.dart';

import '../widgets/duration_sliders.dart';

class LogScaffold extends StatefulWidget {
  const LogScaffold({super.key});

  @override
  State<LogScaffold> createState() => _LogScaffoldState();
}

class _LogScaffoldState extends State<LogScaffold> {
  late CameraController _controller;
  var recognizedImage = "No image";
  bool? flagWarranty = false;
  var recognizedGameId = 0;
  double durationCurrentValue = 60;
  Uint8List imageTest = Uint8List.fromList(new List.empty());
  List<Map> players = [];
  List<Map> locations = [];
  // String defaultLocation = LocationSQL.getDefaultLocationSync() != null
  //     ? LocationSQL.getDefaultLocationSync()!.name
  //     : "";
  String defaultLocation = "";
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

  Future<int?> TakePhoto() async {
    var result = 0;

    print("---------------Got photo");
    try {
      var capturedImage = await _controller.takePicture();
      var bytes = await capturedImage.readAsBytes();

      imageDart.Image? img = imageDart.decodeImage(bytes);
      if (img == null || img?.height == null) return 0;

      //print("Height = ${WidgetsBinding.instance.window.physicalSize.height}");
      var ratio = img.height / 150;
      imageDart.Image resizedImg = imageDart.copyResize(img!,
          width: (img.width / ratio).round(),
          height: (img.height / ratio).round());

      var imgBytes = imageDart.encodeJpg(resizedImg);

      var getGamesWithThumb = await GameThingSQL.getAllGames();

      setState(() {
        imageTest = imgBytes;
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
  }

  void FillLocationName() async {
    var defaultLocationRes = await LocationSQL.getDefaultLocation();
    if (defaultLocationRes != null) {
      setState(() {
        defaultLocation = defaultLocationRes.name;
      });
    }
  }

  @override
  void initState() {
    print("INIT LOG");
    super.initState();

    initializeBggData();
    FillLocationName();

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
    return Scaffold(
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
                ElevatedButton(
                  child: Text("Load all data"),
                  onPressed: (getAllPlaysFromServer),
                ),
                ElevatedButton(
                  child: Text("show games"),
                  onPressed: () async {
                    var allGames = await GameThingSQL.getAllGames();
                    if (allGames == null) return;
                    for (var game in allGames) {
                      print(
                          "Game = ${game.name}, min = ${game.minPlayers}, max = ${game.maxPlayers}");
                    }
                  },
                ),
                ElevatedButton(
                  child: Text("del tables"),
                  onPressed: () {
                    GameThingSQL.deleteDB();
                  },
                ),
                ElevatedButton(
                  child: Text("create tables"),
                  onPressed: () {
                    GameThingSQL.createTable();
                    PlayersSQL.createTable();
                    LocationSQL.createTable();
                  },
                ),
                Flexible(
                    flex: 1,
                    child: Container(
                      //color: Colors.tealAccent,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Center(
                          child: Text(recognizedImage,
                              textAlign: TextAlign.center)),
                    )),
                Flexible(
                    flex: 2,
                    child: Container(
                        //color: Colors.lime,
                        width: MediaQuery.of(context).size.width,
                        child: imageTest.isNotEmpty
                            ? Image.memory(
                                imageTest,
                                height: MediaQuery.of(context).size.height,
                              )
                            : Image.asset('assets/not_bad.png'))),
                Flexible(
                    flex: 1,
                    child: Container(
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
                                          title: Text("Your locations"),
                                          content: SingleChildScrollView(
                                              child: Column(
                                                  children:
                                                      locations.map((location) {
                                            return ElevatedButton(
                                              child: Row(children: [
                                                ChoiceChip(
                                                    label: Text("Default"),
                                                    selected:
                                                        location['isDefault'] ==
                                                            1,
                                                    onSelected: (bool value) {
                                                      setState(() {
                                                        location['isDefault'] =
                                                            value ? 1 : 0;
                                                        if (!value) {
                                                          var locationObject =
                                                              Location(
                                                                  id: location[
                                                                      'id'],
                                                                  name: location[
                                                                      'name'],
                                                                  isDefault: 0);
                                                          LocationSQL
                                                              .updateDefaultLocation(
                                                                  locationObject);
                                                        }
                                                        ;
                                                      });
                                                    }),
                                                Expanded(
                                                    child: Text(
                                                  location['name'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ))
                                              ]),
                                              //value: location['isChecked'],
                                              onPressed: () {
                                                Navigator.of(context,
                                                        rootNavigator: true)
                                                    .pop();
                                                for (var checkedLocation
                                                    in locations) {
                                                  checkedLocation['isChecked'] =
                                                      false;
                                                }
                                                location['isChecked'] = true;

                                                if (location['isDefault'] !=
                                                    1) {
                                                  defaultLocation =
                                                      location['name'];
                                                  for (var existedLocation
                                                      in locations) {
                                                    existedLocation[
                                                        'isDefault'] = 0;
                                                  }
                                                  location['isDefault'] = 1;
                                                  var locationObject = Location(
                                                      id: location['id'],
                                                      name: location['name'],
                                                      isDefault: 1);
                                                  LocationSQL
                                                      .updateDefaultLocation(
                                                          locationObject);
                                                }
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
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                        side: BorderSide(
                                            color: Colors.black12)))),
                            label: Text(defaultLocation.isEmpty
                                ? "Chose location"
                                : defaultLocation),
                            icon: const Icon(Icons.home)))),
                Flexible(
                    flex: 2,
                    child: Container(
                        //color: Colors.green,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: TextField(
                          controller: commentsController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            //prefixIcon: Icon(Icons.search),
                            suffixIcon: Icon(Icons.clear),
                            labelText: 'Comments',
                            hintText: 'Enter your comments',
                            //helperText: 'supporting text',
                            border: OutlineInputBorder(),
                          ),
                        ))),
                Flexible(
                    flex: 1,
                    child: Container(
                        //color: Colors.blueAccent,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: Column(
                          children: [
                            Slider(
                              value: durationCurrentValue,
                              max: 500,
                              divisions: 50,
                              label: durationCurrentValue.round().toString(),
                              onChanged: (double value) {
                                setState(() {
                                  durationCurrentValue = value;
                                });
                              },
                            ),
                            const Text("Duration"),
                          ],
                        ))),
                Flexible(
                    flex: 1,
                    child: Container(
                        //color: Colors.green,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: ElevatedButton.icon(
                            onPressed: () async {
                              if (recognizedGameId <= 0)
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text('No game was chosen to log play'),
                                ));
                              List<Map> bggPlayers = [];
                              for (var player in players.where(
                                  (element) => element['isChecked'] == true)) {
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
                                  await LocationSQL.getDefaultLocation();
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
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                        side: BorderSide(
                                            color: Colors.black12)))),
                            label: Text("Log play"),
                            icon: Icon(Icons.send_and_archive)))),
                Flexible(
                    flex: 1,
                    child: Container(
                        //color: Colors.tealAccent,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: ElevatedButton.icon(
                            onPressed: () async {
                              if (players.isEmpty)
                                players = await getLocalPlayers();
                              showDialog(
                                  context: context,
                                  builder: (BuildContext) {
                                    return StatefulBuilder(
                                        builder: (context, setState) {
                                      return AlertDialog(
                                          //insetPadding: EdgeInsets.zero,
                                          title: Text("Your friends"),
                                          content: SingleChildScrollView(
                                              child: Column(
                                                  children:
                                                      players.map((player) {
                                            return CheckboxListTile(
                                              title: Row(children: [
                                                ChoiceChip(
                                                    label: Text("Win?"),
                                                    selected: player['win'],
                                                    onSelected: (bool? value) {
                                                      setState(() {
                                                        player['win'] = value;
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
                                                  player['isChecked'] = value;
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
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                        side: BorderSide(
                                            color: Colors.black12)))),
                            label: Text("Chose players"),
                            icon: Icon(Icons.people)))),
                Flexible(
                    flex: 1,
                    child: Container(
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
                                        Text(recognizedImage),
                                        Container(
                                          height: 300,
                                          child: CameraPreview(_controller),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .pop();
                                            setState(() {
                                              recognizedImage = "Recognizing";
                                            });
                                            var gameId = await TakePhoto();
                                            var recognizedGameName =
                                                "Cant find similar game";

                                            if (gameId != null) {
                                              var recognizedGame =
                                                  await GameThingSQL
                                                      .selectGameByID(gameId);
                                              if (recognizedGame != null) {
                                                recognizedGameId =
                                                    recognizedGame.id;
                                                recognizedGameName =
                                                    recognizedGame.name;
                                              }
                                            }

                                            setState(() {
                                              recognizedImage =
                                                  recognizedGameName;
                                            });
                                          },
                                          child: const Text('Press me'),
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
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                        side: BorderSide(
                                            color: Colors.black12)))),
                            label: Text("Recognize game"),
                            icon: const Icon(Icons.photo_camera))))
              ],
            )
          ],
        )));
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
          "game = ${gameImage.name}, id = ${gameImage.id}, similarity = ${similarity}");
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
        sessionCookie += (cookie.length > 0 ? ' ' : '') + cookie + ';';
        continue;
      }
      var idx = cookie.indexOf('bggpassword=');
      if (idx != -1) {
        sessionCookie += (cookie.length > 0 ? ' ' : '') +
            'bggpassword=' +
            cookie.substring(idx + 12) +
            ';';
        continue;
      }
      idx = cookie.indexOf('SessionID=');
      if (idx != -1) {
        sessionCookie += (cookie.length > 0 ? ' ' : '') +
            'SessionID=' +
            cookie.substring(idx + 10) +
            ';';
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
