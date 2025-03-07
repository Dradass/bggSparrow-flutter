import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bggApi/bggApi.dart';
import '../db/location_sql.dart';
import 'package:flutter_application_1/models/bgg_location.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import '../db/system_table.dart';
import '../globals.dart';

import 'package:camera/camera.dart';

import 'dart:convert';

import '../db/game_things_sql.dart';
import 'package:image/image.dart' as imageDart;

import 'package:flutter/services.dart';
import 'package:flutter_pixelmatching/flutter_pixelmatching.dart';

class PlayDatePicker extends StatefulWidget {
  static final PlayDatePicker _singleton = PlayDatePicker._internal();

  factory PlayDatePicker() {
    return _singleton;
  }

  PlayDatePicker._internal();
  DateTime playDate = DateTime.now();

  @override
  State<PlayDatePicker> createState() => _PlayDatePickerState();
}

class _PlayDatePickerState extends State<PlayDatePicker> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          var pickedDate = await showDatePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(3000));
          if (pickedDate != null) {
            setState(() {
              widget.playDate = pickedDate;
            });
          }
        },
        label: Text(
            "Playdate: ${DateFormat('yyyy-MM-dd').format(widget.playDate)}"),
        icon: const Icon(Icons.calendar_today));
  }
}

class LocationPicker extends StatefulWidget {
  static final LocationPicker _singleton = LocationPicker._internal();

  factory LocationPicker() {
    return _singleton;
  }

  LocationPicker._internal();

  List<Map> locations = [];
  String selectedLocation = "";

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          if (widget.locations.isEmpty) {
            widget.locations = await getLocalLocations();
          }
          showDialog(
              context: context,
              builder: (BuildContext) {
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                      //insetPadding: EdgeInsets.zero,
                      title: const Text("Your locations"),
                      content: SingleChildScrollView(
                          child: Column(
                              children: widget.locations.map((location) {
                        return ElevatedButton(
                          child: Row(children: [
                            ChoiceChip(
                              label: const Text("Default"),
                              selected: location['isDefault'] == 1,
                              onSelected: (bool value) {
                                setState(() {
                                  for (var location in widget.locations) {
                                    location['isDefault'] = 0;
                                  }

                                  location['isDefault'] = value ? 1 : 0;
                                  print(value);
                                  var locationObject = Location(
                                      id: location['id'],
                                      name: location['name'],
                                      isDefault: value ? 1 : 0);
                                  LocationSQL.updateDefaultLocation(
                                      locationObject);
                                });
                              },
                              shape: const RoundedRectangleBorder(
                                side: BorderSide(color: Colors.black12),
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                              location['name'],
                              overflow: TextOverflow.ellipsis,
                            ))
                          ]),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            for (var checkedLocation in widget.locations) {
                              checkedLocation['isChecked'] = false;
                            }
                            location['isChecked'] = true;
                            widget.selectedLocation = location['name'];
                          },
                        );
                      }).toList())));
                });
              }).then((value) {
            setState(() {});
          });
        },
        style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: Text(widget.selectedLocation.isEmpty
            ? "Select location"
            : widget.selectedLocation),
        icon: const Icon(Icons.home));
  }
}

class Comments extends StatefulWidget {
  static final Comments _singleton = Comments._internal();

  factory Comments() {
    return _singleton;
  }

  Comments._internal();

  final _focusNode = FocusNode();
  final TextEditingController commentsController =
      TextEditingController(text: "#bggSparrow");

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    widget.commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: widget._focusNode,
      controller: widget.commentsController,
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10.0),
          suffixIcon: IconButton(
              onPressed: widget.commentsController.clear,
              icon: const Icon(Icons.clear)),
          labelText: 'Comments',
          hintText: 'Enter your comments',
          border: const UnderlineInputBorder()),
    );
  }
}

class DurationSliderWidget extends StatefulWidget {
  static final DurationSliderWidget _singleton =
      DurationSliderWidget._internal();

  factory DurationSliderWidget() {
    return _singleton;
  }

  DurationSliderWidget._internal();

  double durationCurrentValue = 60;

  @override
  State<DurationSliderWidget> createState() => _DurationSliderWidgetState();
}

class _DurationSliderWidgetState extends State<DurationSliderWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Slider(
          value: widget.durationCurrentValue,
          max: 500,
          divisions: 50,
          label: widget.durationCurrentValue.round().toString(),
          onChanged: (double value) {
            setState(() {
              widget.durationCurrentValue = value;
            });
          },
        ),
        const Text("Duration")
      ],
    );
  }
}

class PlayersPicker extends StatefulWidget {
  static final PlayersPicker _singleton = PlayersPicker._internal();

  factory PlayersPicker() {
    return _singleton;
  }

  PlayersPicker._internal();

  List<Map> players = [];

  @override
  State<PlayersPicker> createState() => _PlayersPickerState();
}

class _PlayersPickerState extends State<PlayersPicker> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          if (widget.players.isEmpty) {
            widget.players = await getLocalPlayers();
          }
          showDialog(
              context: context,
              builder: (BuildContext) {
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                      //insetPadding: EdgeInsets.zero,
                      title: const Text("Your friends"),
                      content: SingleChildScrollView(
                          child: Column(
                              children: widget.players.map((player) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ChoiceChip(
                                  label: const Text("Win?"),
                                  selected: player['win'],
                                  onSelected: (bool? value) {
                                    setState(() {
                                      player['win'] = value;
                                    });
                                  },
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.black12),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                  player['name'],
                                  overflow: TextOverflow.ellipsis,
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
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: const Text("Select players"),
        icon: const Icon(Icons.people));
  }
}

class GamePicker extends StatefulWidget {
  static GamePicker? _singleton;

  factory GamePicker(SearchController searchController,
      List<CameraDescription> cameras, Image _imageWidget) {
    _singleton ??=
        GamePicker._internal(searchController, cameras, _imageWidget);
    return _singleton!;
  }

  GamePicker._internal(this.searchController, this.cameras, this._imageWidget);

  SearchController searchController;
  List<CameraDescription> cameras;
  List<GameThing>? allGames = [];
  List<GameThing>? filteredGames = [];
  Image _imageWidget;

  int recognizedGameId = 0;
  GameThing? recognizedGame;
  late CameraController _controller;

  @override
  State<GamePicker> createState() => _GamePickerState();
}

class _GamePickerState extends State<GamePicker> {
  bool isSearchOnline = false;
  bool onlineSearchModeFromDB = true;
  bool onlineSearchMode = true;

  @override
  void dispose() {
    super.dispose();
    widget.searchController.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.searchController.text = "Select game";

    SystemParameterSQL.selectSystemParameterById(2)
        .then((onlineSearchModeParamValue) => {
              if (onlineSearchModeParamValue != null)
                {
                  print(onlineSearchModeParamValue.value),
                  setState(() {
                    onlineSearchMode = onlineSearchModeParamValue.value == "1";
                  })
                }
            });

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

  Future<int?> TakePhoto() async {
    var result = 0;

    try {
      var capturedImage = await widget._controller.takePicture();
      var bytes = await capturedImage.readAsBytes();

      imageDart.Image? img = imageDart.decodeImage(bytes);
      if (img == null) return 0;

      var ratio = img.height / 150;
      imageDart.Image resizedImg = imageDart.copyResize(img,
          width: (img.width / ratio).round(),
          height: (img.height / ratio).round());

      var imgBytes = imageDart.encodeJpg(resizedImg);

      var getGamesWithThumb = await GameThingSQL.getAllGames();

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
      print("bestSimilarGameID = $bestSimilarGameID");
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
            child: widget._imageWidget),
        Container(
          padding: const EdgeInsets.only(right: 0),
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height,
          // height: MediaQuery.of(context).size.height *
          //     0.5,
          child: SearchAnchor(
              searchController: widget.searchController,
              builder: (context, searchController) {
                return SearchBar(
                  shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: Colors.black12))),
                  controller: searchController,
                  leading: IconButton(
                      onPressed: () {}, icon: const Icon(Icons.search)),
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
                  final gameItem = widget.filteredGames == null
                      ? null
                      : widget.filteredGames![index];
                  return Column(children: [
                    ListTile(
                        title: gameItem?.yearpublished == null
                            ? Text(gameItem!.name,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left)
                            : Text(
                                "${gameItem!.name} (${gameItem.yearpublished})",
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                              ),
                        leading: Container(
                            width: MediaQuery.of(context).size.width * 0.1,
                            child: gameItem != null
                                ? gameItem.thumbBinary != null
                                    ? Image.memory(
                                        base64Decode(gameItem.thumbBinary!))
                                    : null
                                : null),
                        onTap: () async {
                          if (gameItem == null) return;
                          var isSearchOnline = await checkInternetConnection();
                          if (isSearchOnline) {
                            var thumbnail =
                                await getGameThumbFromBGG(gameItem.id);
                            GameThing.GetBinaryThumb(thumbnail).then((value) {
                              if (value != null)
                                setState(() {
                                  widget._imageWidget =
                                      Image.memory(base64Decode(value));
                                });
                            });
                          } else {
                            if (gameItem.thumbBinary != null) {
                              setState(() {
                                widget._imageWidget = Image.memory(
                                    base64Decode(gameItem.thumbBinary!));
                              });
                            } else {
                              widget._imageWidget =
                                  Image.asset('assets/no_image.png');
                            }
                          }
                          setState(() {
                            searchController.closeView(gameItem.name);
                            FocusScope.of(context).unfocus();

                            selectedGameId = gameItem.id;
                            selectedGame = gameItem;
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
        Container(
          padding: const EdgeInsets.only(right: 0),
          width: MediaQuery.of(context).size.width * 0.15,
          child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (dialogBuilder) {
                      return AlertDialog(
                        title: const Text('Place the box in the center'),
                        content: Column(children: [
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
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                    setState(() {
                                      widget.searchController.text =
                                          "Recognizing";
                                    });
                                    var gameId = await TakePhoto();
                                    var recognizedGameName =
                                        "Cant find similar game";

                                    if (gameId != null) {
                                      widget.recognizedGame =
                                          await GameThingSQL.selectGameByID(
                                              gameId);
                                      if (widget.recognizedGame != null) {
                                        widget.recognizedGameId =
                                            widget.recognizedGame!.id;

                                        recognizedGameName =
                                            widget.recognizedGame!.name;
                                      }
                                    }

                                    setState(() {
                                      widget.searchController.text =
                                          recognizedGameName;
                                      if (widget.recognizedGame?.thumbBinary !=
                                          null) {
                                        widget._imageWidget = Image.memory(
                                            base64Decode(widget
                                                .recognizedGame!.thumbBinary
                                                .toString()));
                                      }
                                    });

                                    selectedGameId = widget.recognizedGameId;
                                    selectedGame = widget.recognizedGame;
                                  },
                                  child: const Text('Take a photo'),
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary)))
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
              label: const Text(""),
              icon: const Icon(Icons.photo_camera)),
        ),
        Container(
            padding: const EdgeInsets.only(right: 0),
            width: MediaQuery.of(context).size.width * 0.15,
            child: ChoiceChip(
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  child: onlineSearchMode
                      ? const Icon(Icons.wifi)
                      : const Icon(Icons.wifi_off)),
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
