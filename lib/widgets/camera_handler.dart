import 'package:flutter/material.dart';
import '../db/game_things_sql.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as imageDart;

import 'package:flutter/services.dart';
import 'package:flutter_pixelmatching/flutter_pixelmatching.dart';
import 'dart:convert';

class CameraHandler extends StatefulWidget {
  static CameraHandler? _singleton;

  factory CameraHandler(SearchController searchController,
      List<CameraDescription> cameras, Image _imagewidget) {
    _singleton ??=
        CameraHandler._internal(searchController, cameras, _imagewidget);
    return _singleton!;
  }

  CameraHandler._internal(
      this.searchController, this.cameras, this._imagewidget);
  int recognizedGameId = 0;
  GameThing? recognizedGame;
  SearchController searchController;
  late CameraController _controller;
  List<CameraDescription> cameras;
  Uint8List imageFromCamera = Uint8List.fromList(List.empty());
  var recognizedImage = "No image";
  Image _imagewidget;
  @override
  State<CameraHandler> createState() => _CameraHandlerState();
}

class _CameraHandlerState extends State<CameraHandler> {
  Future<int?> TakePhoto() async {
    var result = 0;

    print("---------------Got photo");
    try {
      var capturedImage = await widget._controller.takePicture();
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
        widget.imageFromCamera = imgBytes;
      });

      if (getGamesWithThumb == null) return 0;
      print("recognizedImage = $widget.recognizedImage");

      int bestGameID = 0;
      bestGameID = await getSimilarGameID(imgBytes, getGamesWithThumb);

      print(bestGameID);
      result = bestGameID;
      return result;
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
      return 0;
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

  @override
  void initState() {
    super.initState();
    widget._controller = CameraController(
        widget.cameras.first, ResolutionPreset.max,
        enableAudio: false);
    widget._controller.initialize().then((_) {
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
    return ElevatedButton.icon(
        onPressed: () {
          showDialog(
              context: context,
              builder: (dialogBuilder) {
                return AlertDialog(
                  title: const Text('Take photo'),
                  content: Column(children: [
                    //Text(recognizedImage),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: CameraPreview(widget._controller),
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        //height: MediaQuery.of(context).size.height * 0.3,
                        // child:
                        // Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            widget.recognizedGameId = 0;
                            Navigator.of(context, rootNavigator: true).pop();
                            setState(() {
                              widget.searchController.text = "Game recognizing";
                            });
                            var gameId = await TakePhoto();
                            var recognizedGameName = "Cant find similar game";

                            if (gameId != null) {
                              widget.recognizedGame =
                                  await GameThingSQL.selectGameByID(gameId);
                              if (widget.recognizedGame != null) {
                                widget.recognizedGameId =
                                    widget.recognizedGame!.id;

                                recognizedGameName =
                                    widget.recognizedGame!.name;
                              }
                            }

                            setState(() {
                              widget.searchController.text = recognizedGameName;
                              if (widget.recognizedGame?.thumbBinary != null) {
                                widget._imagewidget = Image.memory(base64Decode(
                                    widget.recognizedGame!.thumbBinary
                                        .toString()));
                              }
                            });
                          },
                          child: const Text('Take a photo'),
                        )
                        //)
                        )
                  ]),
                );
              });
        },
        style: ButtonStyle(
            // backgroundColor: MaterialStateProperty.all(
            //     Theme.of(context).primaryColor),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: const Text("Recognize game"),
        icon: const Icon(Icons.photo_camera));
  }
}
