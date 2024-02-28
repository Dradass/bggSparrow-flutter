import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:image/image.dart';
import 'package:flutter_application_1/main.dart';
import 'package:camera/camera.dart';
import 'package:image_compare/image_compare.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../db/database_helper.dart';
import '../db/game_things_sql.dart';
import '../models/game_model.dart';
import '../models/game_thing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../bggApi/bggApi.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import 'package:requests/requests.dart';

class LogScaffold extends StatefulWidget {
  const LogScaffold({super.key});

  @override
  State<LogScaffold> createState() => _LogScaffoldState();
}

class _LogScaffoldState extends State<LogScaffold> {
  late CameraController _controller;
  var recognizedImage = "No image";

  Future<int?> TakePhoto() async {
    // print("select test");

    // final database = openDatabase(
    //   // Set the path to the database. Note: Using the `join` function from the
    //   // `path` package is best practice to ensure the path is correctly
    //   // constructed for each platform.
    //   join(await getDatabasesPath(), 'doggie_database.db'),
    //   // When the database is first created, create a table to store dogs.
    //   onCreate: (db, version) {
    //     // Run the CREATE TABLE statement on the database.
    //     return db.execute(
    //       'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
    //     );
    //   },
    //   // Set the version. This executes the onCreate function and provides a
    //   // path to perform database upgrades and downgrades.
    //   version: 1,
    // );
    // final db = await database;
    // final testinfo = await db.rawQuery('select * from dogs');
    // print(testinfo);

    //GameThingSQL.dropTable();
    //GameThingSQL.createTable();

    print('http check');
    var response = await http
        .get(Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=14'));

    var gameItem = GameThing.fromXml(response.body);
    print(gameItem.name);

    //--
    //ImportGameCollectionFromBGG();
    // final allGames = await GameThingSQL.getAllGames();
    // if (allGames != null) {
    //   for (var game in allGames) {
    //     game.CreateBinaryThumb();
    //   }
    // }

    //--

    print("---------------Got photo");
    try {
      // Ensure that the camera is initialized.
      await _controller.initialize();

      // Attempt to take a picture and then get the location
      // where the image file is saved.
      print('get image');
      var capturedImage = await _controller.takePicture();

      var bytes = await capturedImage.readAsBytes();
      final getGamesWithThumb = await GameThingSQL.getAllGames();
      if (getGamesWithThumb == null) return 0;
      print("recognizedImage = $recognizedImage");
      Map<int, double> compareResults = {};
      var matchedGameID = await Isolate.run(() async {
        return getBestComparedImage(bytes, getGamesWithThumb);
      });
      print("matchedGameID = $matchedGameID");
      recognizedImage = matchedGameID.toString();
      return matchedGameID;
      // final getGamesWithThumb = GameThingSQL.getAllGames();
      // getGamesWithThumb.then((gamesWithThumb) {
      //   print("getGamesWithThumb");
      //   if (gamesWithThumb != null) {
      //     var thumbBinList = List.from(
      //         gamesWithThumb.map((e) => base64Decode(e.thumbBinary!)));
      //     final res = listCompare(target: bytes, list: thumbBinList);
      //     res.then((comparingRes) {
      //       print(comparingRes);
      //       var minValue = comparingRes.reduce(min);
      //       var index = comparingRes.indexOf(minValue);
      //       print(minValue);
      //       var finalMin = gamesWithThumb[index];
      //       print("finalMin = ");
      //       print(finalMin.name);
      //       recognizedImage = finalMin.name;
      //     });
      //     print("if (gamesWithThumb != null)");
      //     for (var game in gamesWithThumb) {
      //       Future matchResult = compareImages(
      //           src1: bytes, src2: base64Decode(game.thumbBinary!));
      //       matchResult.then((value) {
      //         compareResults[game.id] = value;
      //       });
      //     }
      //     print(compareResults);
      //   }
      //   // final gamesCount = gamesWithThumb?.length;
      //   // print("-----games count = $gamesCount");
      //   // var imageList1 =
      //   //     gamesWithThumb?.map((e) => base64Decode(e.thumbBinary!)).toList();

      //   // var results = listCompare(target: bytes, list: imageList1!);
      //   // results.then((value) =>
      //   //     {value.forEach((e) => print('Difference: ${e * 100}%'))});
      // });
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ImportGameCollectionFromBGG();
    _controller = CameraController(cameras.first, ResolutionPreset.max);
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
          title: Text("Some app bar text"),
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
                Text(recognizedImage),
                IconButton(
                    onPressed: sendLogRequest, icon: Icon(Icons.network_wifi)),
                IconButton(
                    onPressed: GameThingSQL.createTable,
                    icon: Icon(Icons.add_circle)),
                IconButton(
                    onPressed: () async {
                      final getGames = await GameThingSQL.getAllGames();
                      setState(() {
                        if (getGames != null) {
                          recognizedImage = getGames.length.toString();
                        } else {
                          recognizedImage = "Still no games";
                        }
                      });
                    },
                    icon: Icon(Icons.abc)),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext) {
                            return AlertDialog(
                              title: Text('Take photo'),
                              content: Column(children: [
                                Text("$recognizedImage"),
                                Container(
                                  height: 300,
                                  child: CameraPreview(_controller),
                                ),
                                ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                      final gameId = await TakePhoto();

                                      setState(() {
                                        recognizedImage = gameId.toString();
                                      });
                                    },
                                    child: Text('Press me'))
                              ]),
                            );
                          });
                    },
                    icon: Icon(Icons.photo_camera))
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

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return Container();
  }
}

Future<int?> getBestComparedImage(
    Uint8List bytes, List<GameThing> getGamesWithThumb) async {
  int result = 0;
  if (getGamesWithThumb != null) {
    var thumbBinList =
        List.from(getGamesWithThumb.map((e) => base64Decode(e.thumbBinary!)));
    final res = await listCompare(target: bytes, list: thumbBinList);
    if (res != null) {
      var minValue = res.reduce(min);
      var index = res.indexOf(minValue);
      var finalMin = getGamesWithThumb[index];
      print("finalMin = ");
      print(finalMin.name);
      result = finalMin.id;
      print("result = $result");
    }
  }
  ;
  print(result.toString());
  return result;
}

Future<int?> testIsolate(Uint8List bytes) async {
  int result = 0;
  result = 25;
  return result;
}

Future<int> sendLogRequest() async {
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
    var headers = response.headers;
    var altsvc = response.headers['alt-svc'];
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

    String basicAuth =
        'Basic ' + base64.encode(utf8.encode('dradass:1414141414'));
    var sessionID =
        logCookie.substring(indexOfSessionID + 10, indexOfSessionIDEnd);
    http
        .post(Uri.parse("https://boardgamegeek.com/geekplay.php"),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'cookie': sessionCookie,
            },
            body: playPayload)
        .then((response2) {});
  });

  return 1;
}
