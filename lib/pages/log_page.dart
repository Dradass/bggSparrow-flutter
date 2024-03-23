// TODO - Random game chooser

import 'dart:io';
import 'dart:isolate';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:image/image.dart' as imageDart;
import 'package:flutter_application_1/main.dart';
import 'package:camera/camera.dart';
//import 'package:image_compare/image_compare.dart';
import 'package:path/path.dart';
import '../db/game_things_sql.dart';
import '../db/players_sql.dart';
import '../models/game_model.dart';
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
  DurationSlider durationSlider = const DurationSlider();

  var logData = {
    "playdate": "2024-03-15",
    "comments": "comments go here",
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
  void initState() {
    print("INIT LOG");
    super.initState();

    initializeBggData();

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
        backgroundColor: Colors.blue,
        appBar: AppBar(
          title: const Text("Log play screen"),
          centerTitle: true,
          backgroundColor: Colors.amberAccent,
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
                        child: Image.memory(
                          imageTest,
                          height: MediaQuery.of(context).size.height,
                        ))),
                Flexible(
                    flex: 1,
                    child: Container(
                        //color: Colors.green,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: TextField(
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                          decoration: InputDecoration(
                            //prefixIcon: Icon(Icons.search),
                            suffixIcon: Icon(Icons.clear),
                            labelText: '#bggSparrow',
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
                            Text("Duration"),
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
                              String stringData = json.encode(logData);
                              print(stringData);
                              await sendLogRequest(stringData);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('Request was sent'),
                              ));
                            },
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.amber),
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
                              print(
                                  "DATE = ${DateFormat('yyyy-MM-dd').format(DateTime.now())}");
                              players = await FillPlayers();
                              showDialog(
                                  context: context,
                                  builder: (BuildContext) {
                                    return StatefulBuilder(
                                        builder: (context, setState) {
                                      return AlertDialog(
                                          title: Text("Your friends"),
                                          content: Column(
                                              children: players.map((player) {
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
                                                Text(player['name'])
                                              ]),
                                              value: player['isChecked'],
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  player['isChecked'] = value;
                                                });
                                              },
                                            );
                                          }).toList()));
                                    });
                                  });
                            },
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.amber),
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
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.amber),
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

  String playPayload = json.encode({
    "playdate": "2024-02-28",
    "comments": "comments go here",
    "length": 60,
    "twitter": "false",
    "minutes": 60,
    "location": "Home",
    "objectid": "158899",
    "hours": 0,
    "quantity": "1",
    "action": "save",
    "date": "2024-02-28T05:00:00.000Z",
    "players": [
      {
        "username": "Test",
        "userid": 0,
        "repeat": "true",
        "name": "Non-BGG Friend",
        "selected": "false"
      },
      {
        "username": "youruserid",
        "userid": 2364945,
        "name": "Me!",
        "selected": "false"
      }
    ],
    "objecttype": "thing",
    "ajax": 1
  });

  http
      .post(Uri.parse("https://boardgamegeek.com/login/api/v1"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: bodyLogin)
      .then((response) {
    var logCookie = response.headers['set-cookie'];
    var indexOfSessionID = logCookie!.indexOf("SessionID=");
    var indexOfSessionIDEnd = logCookie!.indexOf(";", indexOfSessionID);

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
    print(sessionCookie);

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
