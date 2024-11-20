import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../db/game_things_sql.dart';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:flutter_application_1/main.dart';

import 'dart:convert';

import 'package:flutter_pixelmatching/flutter_pixelmatching.dart';

class TakePhotoButton extends StatefulWidget {
  int recognizedGameId = 0;

  SearchController searchController = SearchController();
  Uint8List imageFromCamera = Uint8List.fromList(List.empty());

  static final TakePhotoButton _singleton = TakePhotoButton._internal();
  TakePhotoButton._internal();

  factory TakePhotoButton(int recognizedGameId,
      SearchController searchController, Uint8List imageFromCamera) {
    recognizedGameId = recognizedGameId;
    searchController = searchController;
    imageFromCamera = imageFromCamera;
    return _singleton;
  }

  @override
  State<TakePhotoButton> createState() => _TakePhotoButtonState();
}

class _TakePhotoButtonState extends State<TakePhotoButton> {
  late CameraController _controller;
  @override
  void initState() {
    super.initState();

    print("new init");
    print(cameras);
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

  Future<int?> TakePhoto() async {
    var result = 0;

    print("---------------Got photo");
    return null;
    // try {
    //   //var capturedImage = await _controller.takePicture();
    //   //var bytes = await capturedImage.readAsBytes();
    //   var bytes =
    //       base64Decode((await GameThingSQL.selectGameByID(13))!.thumbBinary!);

    //   imageDart.Image? img = imageDart.decodeImage(bytes);
    //   if (img == null) return 0;

    //   //print("Height = ${WidgetsBinding.instance.window.physicalSize.height}");
    //   var ratio = img.height / 150;
    //   imageDart.Image resizedImg = imageDart.copyResize(img,
    //       width: (img.width / ratio).round(),
    //       height: (img.height / ratio).round());

    //   var imgBytes = imageDart.encodeJpg(resizedImg);

    //   var getGamesWithThumb = await GameThingSQL.getAllGames();

    //   setState(() {
    //     widget.imageFromCamera = imgBytes;
    //   });

    //   if (getGamesWithThumb == null) return 0;

    //   Map<int, double> compareResults = {};

    //   int bestGameID = 0;
    //   bestGameID = await getSimilarGameID(imgBytes, getGamesWithThumb);
    //   // bestGameID = await Isolate.run(() async {
    //   //   return getSimilarGameID(imgBytes, getGamesWithThumb);
    //   // });
    //   print(bestGameID);
    //   result = bestGameID;
    //   return result;
    // } catch (e) {
    //   // If an error occurs, log the error to the console.
    //   print(e);
    //   return 0;
    // }
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext) {
                return AlertDialog(
                  title: const Text('Take photo'),
                  content: Column(children: [
                    SizedBox(
                      height: 300,
                      child: CameraPreview(_controller),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        widget.recognizedGameId = 0;
                        Navigator.of(context, rootNavigator: true).pop();
                        setState(() {
                          widget.searchController.text = "Game recognizing";
                        });
                        var gameId = await TakePhoto();
                        var recognizedGameName = "Cant find similar game";

                        if (gameId != null) {
                          var recognizedGame =
                              await GameThingSQL.selectGameByID(gameId);
                          if (recognizedGame != null) {
                            widget.recognizedGameId = recognizedGame.id;
                            recognizedGameName = recognizedGame.name;
                          }
                        }

                        setState(() {
                          // recognizedImage =
                          //     recognizedGameName;
                          widget.searchController.text = recognizedGameName;
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
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: const Text("Recognize game"),
        icon: const Icon(Icons.photo_camera));
  }
}
