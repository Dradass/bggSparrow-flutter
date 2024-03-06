// TODO - Random game chooser

import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:image/image.dart' as imageDart;
import 'package:flutter_application_1/main.dart';
import 'package:camera/camera.dart';
//import 'package:image_compare/image_compare.dart';
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
import 'package:flutter_pixelmatching/flutter_pixelmatching.dart';

class LogScaffold extends StatefulWidget {
  const LogScaffold({super.key});

  @override
  State<LogScaffold> createState() => _LogScaffoldState();
}

class _LogScaffoldState extends State<LogScaffold> {
  late CameraController _controller;
  var recognizedImage = "No image";
  Uint8List imageTest = Uint8List.fromList(new List.empty());
  //Uint8List imageFounded = Uint8List.fromList(new List.empty());

  Future<int?> TakePhoto(XFile capturedImage) async {
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

    // print('http check');
    // var response = await http
    //     .get(Uri.parse('https://boardgamegeek.com//xmlapi2/things?id=14'));

    // var gameItem = GameThing.fromXml(response.body);
    // print(gameItem.name);
    var result = 0;

    print("---------------Got photo");
    try {
      // Ensure that the camera is initialized.
      //await _controller.initialize();

      // Attempt to take a picture and then get the location
      // where the image file is saved.
      print('get image');

      // ByteData bytesData = await rootBundle.load('assets/colt3.jpg');
      // var bytes = Uint8List.sublistView(bytesData);

      // var random = Random().nextInt(2);
      // print(random);

      // var url1 = "https://studiobombyx.com/assets/SSAP_3dbox_right-2.png";
      // var url2 = "https://media.lavkaigr.ru/catalog/2017/12/colt-express.jpg";

      // var finalUrl = random == 1 ? url1 : url2;
      // print(finalUrl);

      //---
      // http.Response response = await http.get(Uri.parse(finalUrl));
      // var bytes = response.bodyBytes; //Uint8List
      // print("image bytes = ${bytes}");
      //---

      //var capturedImage = await _controller.takePicture();
      var bytes = await capturedImage.readAsBytes();

      imageDart.Image? img = imageDart.decodeImage(bytes);
      if (img == null || img?.height == null) return 0;

      var ratio = img.height / 150;
      imageDart.Image resizedImg = imageDart.copyResize(img!,
          width: (img.width / ratio).round(),
          height: (img.height / ratio).round());

      var imgBytes = imageDart.encodeJpg(imageDart.grayscale(resizedImg));

      var getGamesWithThumb = await GameThingSQL.getAllGames();

      setState(() {
        imageTest = imgBytes;
      });

      if (getGamesWithThumb == null) return 0;
      print("recognizedImage = $recognizedImage");
      Map<int, double> compareResults = {};

      // var matchedGameID = await Isolate.run(() async {
      //   return getBestComparedImage(bytes, getGamesWithThumb);
      // });
      //var matchedGameID = await getBestComparedImage(bytes, getGamesWithThumb);

      // final image1 = Uri.parse(
      //     "https://cf.geekdo-images.com/2HKX0QANk_DY7CIVK5O5fQ__thumb/img/zcjkqn_HYDIIyVAZaAxJIkurQRg=/fit-in/200x150/filters:strip_icc()/pic2869710.jpg");

      int bestGameID = 0;
      bestGameID = await getSimilarGameID(imgBytes, getGamesWithThumb);
      // bestGameID = await Isolate.run(() async {
      //   return getSimilarGameID(imgBytes, getGamesWithThumb);
      // });
      print(bestGameID);
      //bestGame.then((value) => bestGameID = value!);

      // final matching = PixelMatching();
      // await matching.initialize(image: imageBytes);

      // var bestSimilarity = 0.0;
      // var bestSimilarGameID = 0;
      // if (matching.isInitialized) {
      //   for (var gameImage in getGamesWithThumb) {
      //     if (gameImage.thumbBinary == null) break;
      //     final binaryImage = base64Decode(gameImage.thumbBinary!);

      //     var similarity = matching.similarity(binaryImage);
      //     similarity.then((value) {
      //       print("game = ${gameImage.name}, similarity = ${value}");
      //       if (value > bestSimilarity) {
      //         bestSimilarGameID = gameImage.id;
      //         bestSimilarity = value;
      //       }
      //       ;
      //     });

      //     // final result = matching.
      //     //     imageDart.Image.fromBytes(200, 200, bytes),
      //     //     imageDart.Image.fromBytes(200, 200, binaryImage));
      //   }
      // }
      result = bestGameID;
      // print("matchedGameID = $matchedGameID");
      // recognizedImage = matchedGameID.toString();
      // result = matchedGameID!;
      return result;
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
      return 0;
    }
  }

  // /// Setup Camera
  // ///
  // initializeCamera() async {
  //   final cameras = await availableCameras();
  //   final camera = cameras[0];
  //   _controller =
  //       CameraController(camera, ResolutionPreset.high, enableAudio: false);
  //   await _controller.initialize();
  //   //_controller?.startImageStream(cameraStream);
  //   setState(() {});
  // }

  @override
  void initState() {
    print("INIT LOG");
    // TODO: implement initState
    super.initState();
    //_controller.initialize();
    ImportGameCollectionFromBGG();

    var imageTest = rootBundle
        .load("assets/not_bad.png")
        .then((value) => value.buffer.asUint8List());

    imageTest.then((value) => null);

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
                Image.memory(imageTest),
                IconButton(
                    onPressed: sendLogRequest, icon: Icon(Icons.network_wifi)),
                IconButton(
                    onPressed: GameThingSQL.createTable,
                    icon: Icon(Icons.add_circle)),
                IconButton(
                    onPressed: GameThingSQL.dropTable,
                    icon: Icon(Icons.delete)),
                IconButton(
                    onPressed: () async {
                      var getGames = await GameThingSQL.getAllGames();
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
                      //_controller.initialize();
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
                                      // Slow camera fix
                                      var capturedImage =
                                          await _controller.takePicture();

                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                      setState(() {
                                        recognizedImage = "Recognizing";
                                      });
                                      var gameId =
                                          await TakePhoto(capturedImage);
                                      var recognizedGameName =
                                          "Cant find similar game";

                                      if (gameId != null) {
                                        var recognizedGame =
                                            await GameThingSQL.selectGameByID(
                                                gameId);
                                        if (recognizedGame != null)
                                          recognizedGameName =
                                              recognizedGame.name;
                                      }

                                      setState(() {
                                        recognizedImage = recognizedGameName;
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

// class TakePictureScreenState extends State<TakePictureScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;

//   @override
//   void initState() {
//     super.initState();
//     // To display the current output from the Camera,
//     // create a CameraController.
//     _controller = CameraController(
//       // Get a specific camera from the list of available cameras.
//       widget.camera,
//       // Define the resolution to use.
//       ResolutionPreset.medium,
//     );

//     // Next, initialize the controller. This returns a Future.
//     _initializeControllerFuture = _controller.initialize();
//   }

//   @override
//   void dispose() {
//     // Dispose of the controller when the widget is disposed.
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Fill this out in the next steps.
//     return Container();
//   }
// }

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
      // imageDart.Image? img = imageDart.decodeImage(binaryImage);
      // var imgBytes = imageDart.encodeJpg(imageDart.grayscale(img!));

      //TODO resize bgg game image to camera game resolution

      final similarity = await matching.similarity(binaryImage);
      // similarity.then((value) {
      //   print("game = ${gameImage.name}, similarity = ${value}");
      //   if (value > bestSimilarity) {
      //     bestSimilarGameID = gameImage.id;
      //     bestSimilarity = value;
      //   }
      //   ;
      // });
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

// Future<int?> getBestComparedImage(
//     Uint8List bytes, List<GameThing> getGamesWithThumb) async {
//   int result = 0;
//   if (getGamesWithThumb != null) {
//     final thumbBinList =
//         List.from(getGamesWithThumb.map((e) => base64Decode(e.thumbBinary!)));
//     final res = await listCompare(target: bytes, list: thumbBinList);
//     if (res != null) {
//       final minValue = res.reduce(min);
//       final index = res.indexOf(minValue);
//       final finalMin = getGamesWithThumb[index];
//       result = finalMin.id;
//     }
//   }
//   ;
//   print(result.toString());
//   return result;
// }

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

//------------------------------------------------------------------------------

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import '../matching_view.dart';

// // ignore: depend_on_referenced_packages
// import 'package:image_picker/image_picker.dart';

// void main() {
//   runApp(const MaterialApp(home: LogScaffold()));
// }

// class LogScaffold extends StatefulWidget {
//   const LogScaffold({super.key});

//   @override
//   State<LogScaffold> createState() => _LogScaffoldState();
// }

// class _LogScaffoldState extends State<LogScaffold> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PixelMatching Sample'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             buildFromGallery(),
//             buildFromCamera(),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build a button to fetch from the gallery, and set `image1` on image selection.
//   buildFromGallery() {
//     return TextButton.icon(
//       icon: const Icon(Icons.photo),
//       label: const Text("From Gallery"),
//       onPressed: () async {
//         ImagePicker().pickImage(source: ImageSource.gallery).then(
//           (value) async {
//             final Uint8List? target = await value?.readAsBytes();
//             if (target != null) {
//               openMatchingView(target);
//             }
//           },
//         );
//       },
//     );
//   }

//   /// Build a button to fetch from the camera, and set `image1` on image selection.
//   buildFromCamera() {
//     return TextButton.icon(
//       label: const Text("From Camera"),
//       icon: const Icon(Icons.camera),
//       onPressed: () async {
//         ImagePicker().pickImage(source: ImageSource.camera).then(
//           (value) async {
//             final Uint8List? target = await value?.readAsBytes();
//             if (target != null) {
//               openMatchingView(target);
//             }
//           },
//         );
//       },
//     );
//   }

//   openMatchingView(Uint8List target) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) {
//           return MatchingView(target: target);
//         },
//       ),
//     );
//   }
// }
