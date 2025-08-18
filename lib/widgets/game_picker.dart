import 'package:flutter/material.dart';
import '../bggApi/bgg_api.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import '../db/system_table.dart';
import '../globals.dart';
import '../s.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../db/game_things_sql.dart';
import 'package:image/image.dart' as image_dart;
import 'package:flutter/services.dart';
import 'package:flutter_pixelmatching/flutter_pixelmatching.dart';
import 'dart:developer';

class GamePicker extends StatefulWidget {
  static GamePicker? _singleton;

  factory GamePicker(
    SearchController searchController,
    List<CameraDescription> cameras,
    Image imageWidget,
  ) {
    _singleton ??= GamePicker._internal(searchController, cameras, imageWidget);
    return _singleton!;
  }

  GamePicker._internal(this.searchController, this.cameras, this.imageWidget);

  SearchController searchController;
  List<CameraDescription> cameras;
  List<GameThing>? allGames = [];
  List<GameThing>? filteredGames = [];
  Image imageWidget;

  int recognizedGameId = 0;
  GameThing? recognizedGame;
  late CameraController _cameraController;

  @override
  State<GamePicker> createState() => _GamePickerState();
}

class _GamePickerState extends State<GamePicker> {
  bool isSearchOnline = false;
  bool onlineSearchModeFromDB = true;
  bool onlineSearchMode = true;
  bool _isCameraInitialized = false;
  late final AppLifecycleListener listener;

  @override
  void dispose() {
    super.dispose();
    widget.searchController.dispose();
    widget._cameraController.dispose();
  }

  @override
  void initState() {
    super.initState();
    listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );

    SystemParameterSQL.selectSystemParameterById(2)
        .then((onlineSearchModeParamValue) => {
              if (onlineSearchModeParamValue != null)
                {
                  setState(() {
                    onlineSearchMode = onlineSearchModeParamValue.value == "1";
                  })
                }
            });

    _initializeCamera();
  }

  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        () => {};
      case AppLifecycleState.resumed:
        if (!_isCameraInitialized) {
          _initializeCamera();
        }
      case AppLifecycleState.inactive:
        () {
          widget._cameraController.dispose();
        };
      case AppLifecycleState.hidden:
        () => {};
      case AppLifecycleState.paused:
        widget._cameraController.stopImageStream();
        widget._cameraController.dispose();
        _isCameraInitialized = false;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      widget._cameraController = CameraController(
          cameras[0], ResolutionPreset.max,
          enableAudio: false);
      await widget._cameraController.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Camera initialization error: $e')));
      }
    }
  }

  Future<int?> takePhoto() async {
    var result = 0;

    try {
      var capturedImage = await widget._cameraController.takePicture();
      var bytes = await capturedImage.readAsBytes();

      image_dart.Image? img = image_dart.decodeImage(bytes);
      if (img == null) return 0;

      var ratio = img.height / 150;
      image_dart.Image resizedImg = image_dart.copyResize(img,
          width: (img.width / ratio).round(),
          height: (img.height / ratio).round());

      var imgBytes = image_dart.encodeJpg(resizedImg);

      var getGamesWithThumb = await GameThingSQL.getAllGames();

      if (getGamesWithThumb == null) return 0;
      log("recognizedImage = $widget.recognizedImage");

      int bestGameID = 0;
      bestGameID = await getSimilarGameID(imgBytes, getGamesWithThumb);

      log(bestGameID.toString());
      result = bestGameID;
      return result;
    } catch (e) {
      // If an error occurs, log the error to the console.
      log(e.toString());
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
        log("game = ${gameImage.name}, id = ${gameImage.id}, similarity = $similarity");
        if (similarity > bestSimilarity) {
          bestSimilarGameID = gameImage.id;
          bestSimilarity = similarity;
        }
      }
      log("bestSimilarGameID = $bestSimilarGameID");
      matching.dispose();
      return bestSimilarGameID;
    }
    matching.dispose();
    return bestSimilarGameID;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
            padding: const EdgeInsets.only(right: 0),
            width: MediaQuery.of(context).size.width * 0.2,
            child: widget.imageWidget),
        Container(
          padding: const EdgeInsets.only(right: 0),
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height,
          child: SearchAnchor(
              searchController: widget.searchController,
              builder: (context2, searchController) {
                return SearchBar(
                  hintText: widget.searchController.text,
                  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                  elevation: const WidgetStatePropertyAll(0.0),
                  shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: Colors.black12))),
                  controller: searchController,
                  textStyle: WidgetStateProperty.all<TextStyle>(
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
                  leading: Builder(builder: (context3) {
                    return IconButton(
                        key: selectGameButtonKey,
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {},
                        icon: const Icon(Icons.search));
                  }),
                  onTap: () async {
                    widget.searchController.text = "";
                    isSearchOnline = await checkInternetConnection();
                    searchController.openView();
                  },
                  onChanged: (_) {
                    searchController.openView();
                  },
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 1.0)),
                );
              },
              suggestionsBuilder: (context, searchController) async {
                if (isSearchOnline && onlineSearchMode) {
                  widget.filteredGames = await searchGamesFromBGG(
                      widget.searchController.text.toLowerCase());
                } else {
                  widget.filteredGames = await searchGamesFromLocalDB(
                      widget.searchController.text.toLowerCase());
                }
                return List<Column>.generate(
                    widget.filteredGames == null
                        ? 0
                        : widget.filteredGames!.length, (int index) {
                  GameThing? gameItem = widget.filteredGames == null
                      ? null
                      : widget.filteredGames![index];
                  return gameItem != null
                      ? Column(children: [
                          ListTile(
                              textColor: Theme.of(context).colorScheme.primary,
                              title: gameItem.yearpublished == null
                                  ? Text(gameItem.name,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left)
                                  : Text(
                                      "${gameItem.name} (${gameItem.yearpublished})",
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                    ),
                              leading: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.1,
                                  child: gameItem.thumbBinary != null
                                      ? Image.memory(
                                          base64Decode(gameItem.thumbBinary!))
                                      : null),
                              onTap: () async {
                                var isSearchOnline =
                                    await checkInternetConnection();
                                if (isSearchOnline) {
                                  var thumbnail =
                                      await getGameThumbFromBGG(gameItem.id);
                                  GameThing.getBinaryThumb(thumbnail)
                                      .then((value) {
                                    if (value != null) {
                                      setState(() {
                                        widget.imageWidget =
                                            Image.memory(base64Decode(value));
                                      });
                                    }
                                  });
                                } else {
                                  if (gameItem.thumbBinary != null) {
                                    setState(() {
                                      widget.imageWidget = Image.memory(
                                          base64Decode(gameItem.thumbBinary!));
                                    });
                                  } else {
                                    widget.imageWidget =
                                        Image.asset('assets/no_image.png');
                                  }
                                }
                                setState(() {
                                  selectedGameId = gameItem.id;
                                  selectedGame = gameItem;
                                  searchController.closeView(gameItem.name);
                                  FocusScope.of(context).unfocus();
                                });
                              }),
                          const Divider(
                            height: 0,
                            color: Colors.black12,
                          ),
                        ])
                      : const Column(children: []);
                });
              }),
        ),
        Container(
            padding: const EdgeInsets.only(right: 0),
            width: MediaQuery.of(context).size.width * 0.15,
            child: Builder(builder: (context3) {
              return ElevatedButton.icon(
                  key: recognizeGameButtonKey,
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (dialogBuilder) {
                          return AlertDialog(
                            title:
                                Text(S.of(context).placeTheTopOfTheBoxInFrame),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ValueListenableBuilder<bool>(
                                    valueListenable:
                                        isLoadedAllGamesImagesNotifier,
                                    builder: (context, value, _) {
                                      return value
                                          ? Container()
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              child: Text(
                                                maxLines: 3,
                                                value
                                                    ? ""
                                                    : "*${S.of(context).warningNotAllImagesLoaded}",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                ),
                                              ));
                                    },
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    height: MediaQuery.of(context).size.height *
                                        0.5,
                                    child:
                                        CameraPreview(widget._cameraController),
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      // height:
                                      //     MediaQuery.of(context).size.height * 0.15,
                                      child: ElevatedButton(
                                          onPressed: () async {
                                            widget.recognizedGameId = 0;
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .pop();
                                            setState(() {
                                              widget.searchController.text =
                                                  S.of(context).recognizing;
                                            });
                                            var gameId = await takePhoto();
                                            var recognizedGameName = S
                                                .of(context)
                                                .cantFindSimilarGame;

                                            if (gameId != null) {
                                              widget.recognizedGame =
                                                  await GameThingSQL
                                                      .selectGameByID(gameId);
                                              if (widget.recognizedGame !=
                                                  null) {
                                                widget.recognizedGameId =
                                                    widget.recognizedGame!.id;

                                                recognizedGameName =
                                                    widget.recognizedGame!.name;
                                              }
                                            }

                                            setState(() {
                                              widget.searchController.text =
                                                  recognizedGameName;
                                              if (widget.recognizedGame
                                                      ?.thumbBinary !=
                                                  null) {
                                                widget.imageWidget =
                                                    Image.memory(base64Decode(
                                                        widget.recognizedGame!
                                                            .thumbBinary
                                                            .toString()));
                                              }
                                            });

                                            selectedGameId =
                                                widget.recognizedGameId;
                                            selectedGame =
                                                widget.recognizedGame;
                                          },
                                          style: ButtonStyle(
                                              iconColor:
                                                  WidgetStateProperty.all(
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary)),
                                          child: Text(S.of(context).recognize)))
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
                  label: const Text(""),
                  icon: const Icon(Icons.document_scanner));
            })),
        Container(
            padding: const EdgeInsets.only(right: 0),
            width: MediaQuery.of(context).size.width * 0.15,
            child: ChoiceChip(
              key: swapSearchModeKey,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  child: onlineSearchMode
                      ? Icon(Icons.wifi,
                          color: Theme.of(context).colorScheme.primary)
                      : Icon(Icons.wifi_off,
                          color: Theme.of(context).colorScheme.primary)),
              selected: onlineSearchMode,
              onSelected: (bool value) {
                setState(() {
                  onlineSearchMode = value;
                });
              },
            ))
      ],
    );
  }
}
