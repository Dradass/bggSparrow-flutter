import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:flutter_application_1/models/custom_list_model.dart';
import '../db/game_things_sql.dart';
import '../db/custom_list_sql.dart';
import 'dart:developer';

class GameHelper extends StatefulWidget {
  const GameHelper({super.key});

  @override
  State<GameHelper> createState() => _GameHelperState();
}

class _GameHelperState extends State<GameHelper> {
  double chosenPlayersCount = 1;
  String chosenGame = "Get some random game";
  RangeValues maxRangeValues = const RangeValues(0, 0);
  bool onlyOwnedGames = true;
  int gamesFilterNeedClear = 0;
  List<Map<GameThing, int>> gamesFromFilter = [];
  List<Map<GameThing, int>> allItems = [];
  List<GameThing>? allGames = [];
  final SearchController searchController = SearchController();
  Map<int, String> gamesList = {};
  var chosenGameListId = 0;
  String? createListErrorText;
  String? createListHelperText;
  final TextEditingController newCustimListNameController =
      TextEditingController();
  bool isSystemDropDownItem = true;

  Future<void> updateGamesToAll() async {
    allGames = await GameThingSQL.getAllGames();
    if (allGames == null) {
      log("No games");
      return;
    }
    allGames!.sort((a, b) => a.name.compareTo(b.name));
    gamesFromFilter.clear();
    for (var game in allGames!) {
      if (onlyOwnedGames) {
        if (game.owned == 0) continue;
      }
      if (isGameMatchChosenPlayersCount(
          game, chosenPlayersCount, maxRangeValues)) {
        gamesFromFilter.add({game: game.owned});
      }
    }
  }

  Future<void> updateCustomLists() async {
    CustomListSQL.getAllCustomLists().then((lists) {
      gamesList[0] = "All";
      var customLists = (List.generate(
          lists.length, (index) => CustomList.fromJson(lists[index])));
      if (customLists.isEmpty) return;
      for (var customList in customLists) {
        gamesList[customList.id] = customList.name;
      }
    });
  }

  List<GameThing> getSelectedGames() {
    List<GameThing> selectedGames = [];
    for (var gameFromFilter in gamesFromFilter) {
      if (gameFromFilter.values.first > 0) {
        selectedGames.add(gameFromFilter.keys.first);
      }
    }
    return selectedGames;
  }

  Future<bool> updateCustomList(
      List<GameThing> selectedGames, int listId) async {
    selectedGames.sort((a, b) => a.id.compareTo(b.id));
    final selectedGamesString = selectedGames.map((x) => x.id).join(";");
    var existedList = await CustomListSQL.selectCustomListById(listId);
    if (existedList == null) {
      return false;
    }
    var newList = CustomList(
        id: listId, name: existedList.name, value: selectedGamesString);
    CustomListSQL.updateCustomList(newList);
    return true;
  }

  Future<void> updateGamesFromCustomList(int listId) async {
    if (chosenGameListId == 0) {
      await updateGamesToAll();
      setState(() {});
      return;
    }
    var customList = await CustomListSQL.selectCustomListById(chosenGameListId);
    if (customList != null) {
      var gamesString = customList.value;
      if (gamesString != null) {
        var gamesList = gamesString.split(';');
        gamesFromFilter.clear();
        for (var game in gamesList) {
          var gameThing = await GameThingSQL.selectGameByID(int.parse(game));
          gamesFromFilter.add({gameThing!: 1});
        }
        gamesFromFilter
            .sort((a, b) => a.keys.first.name.compareTo(b.keys.first.name));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    updateCustomLists();

    return Scaffold(
        body: SafeArea(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Flexible(
            flex: 1,
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: const Text(" "))),
        Flexible(
            flex: 1,
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    RangeSlider(
                      values: maxRangeValues,
                      max: 10,
                      divisions: 10,
                      labels: RangeLabels(
                          maxRangeValues.start.round().toString(),
                          maxRangeValues.end.round().toString()),
                      onChanged: (RangeValues values) {
                        setState(() {
                          maxRangeValues = values;
                        });
                      },
                    ),
                    const Text("Max players count"),
                  ],
                ))),
        Flexible(
            flex: 1,
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    Slider(
                      value: chosenPlayersCount,
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: chosenPlayersCount.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          chosenPlayersCount = value;
                        });
                      },
                    ),
                    const Text("Players count"),
                  ],
                ))),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.05,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: double.maxFinite,
                child: ChoiceChip(
                  label: SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 1,
                      child: const Text("Only owned games")),
                  selected: onlyOwnedGames,
                  onSelected: (bool value) {
                    setState(() {
                      onlyOwnedGames = value;
                    });
                  },
                )),
            Container(
                color: Colors.brown,
                width: MediaQuery.of(context).size.width * 0.5,
                height: double.maxFinite,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await updateGamesFromCustomList(chosenGameListId);
                    await updateCustomLists();
                    showDialog(
                        context: context,
                        builder: (buildContext) {
                          return StatefulBuilder(builder: (context, setState) {
                            setState(() {});
                            return AlertDialog(
                                content: Column(children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Game'),
                                  Container(
                                      color: Colors.red,
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      child: ElevatedButton(
                                          onPressed: () {
                                            for (var game in allGames!) {
                                              if (!gamesFromFilter.any((x) =>
                                                  x.keys.first == game)) {
                                                gamesFromFilter.add({game: 0});
                                              }
                                            }
                                            setState(() {});
                                          },
                                          child: const Text("Show all games"))),
                                  Row(children: [
                                    const Text('Votes'),
                                    Checkbox(
                                        value: gamesFilterNeedClear == 1,
                                        onChanged: ((value) {
                                          for (var gameFromFilter
                                              in gamesFromFilter) {
                                            gameFromFilter.update(
                                                gameFromFilter.keys.first,
                                                (value2) =>
                                                    value2 = value! ? 1 : 0);
                                          }
                                          setState(
                                            () {
                                              gamesFilterNeedClear =
                                                  value! ? 1 : 0;
                                            },
                                          );
                                        }))
                                  ]),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.68,
                                      child: ExpansionTile(
                                          shape: Border(),
                                          title: const Text('Games lists'),
                                          children: [
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Container(
                                                      child: Row(children: [
                                                    ElevatedButton(
                                                        onPressed:
                                                            isSystemDropDownItem
                                                                ? null
                                                                : () async {
                                                                    setState(
                                                                        () {
                                                                      createListErrorText =
                                                                          null;
                                                                      createListHelperText =
                                                                          null;
                                                                    });
                                                                    var selectedGames =
                                                                        getSelectedGames();
                                                                    if (!await updateCustomList(
                                                                        selectedGames,
                                                                        chosenGameListId)) {
                                                                      setState(
                                                                          () {
                                                                        createListErrorText =
                                                                            "Cant update this list";
                                                                      });
                                                                      return;
                                                                    }
                                                                    setState(
                                                                        () {});
                                                                    setState(
                                                                        () {
                                                                      createListHelperText =
                                                                          "List was updated";
                                                                    });
                                                                  },
                                                        child: const Text(
                                                            'Update')),
                                                    DropdownButton(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      value: gamesList
                                                              .isNotEmpty
                                                          ? gamesList[
                                                              chosenGameListId]
                                                          : null,
                                                      onChanged: (String?
                                                          value) async {
                                                        chosenGameListId = gamesList
                                                            .entries
                                                            .firstWhere(
                                                                (entry) =>
                                                                    entry
                                                                        .value ==
                                                                    value)
                                                            .key;
                                                        isSystemDropDownItem =
                                                            chosenGameListId ==
                                                                    0
                                                                ? true
                                                                : false;

                                                        await updateGamesFromCustomList(
                                                            chosenGameListId);
                                                        setState(() {});
                                                      },
                                                      items: gamesList.values.map<
                                                              DropdownMenuItem<
                                                                  String>>(
                                                          (String value) {
                                                        return DropdownMenuItem<
                                                                String>(
                                                            value: value,
                                                            child: Text(value));
                                                      }).toList(),
                                                    )
                                                  ])),
                                                  ElevatedButton(
                                                      onPressed:
                                                          isSystemDropDownItem
                                                              ? null
                                                              : () async {
                                                                  setState(() {
                                                                    createListErrorText =
                                                                        null;
                                                                    createListHelperText =
                                                                        null;
                                                                  });

                                                                  final customList =
                                                                      await CustomListSQL
                                                                          .selectCustomListById(
                                                                              chosenGameListId);
                                                                  if (customList ==
                                                                      null) {
                                                                    return;
                                                                  }
                                                                  CustomListSQL
                                                                      .deleteCustomList(
                                                                          customList);
                                                                  gamesList.remove(
                                                                      customList
                                                                          .id);
                                                                  setState(
                                                                      () {});
                                                                  setState(() {
                                                                    createListHelperText =
                                                                        "List was deleted";
                                                                  });
                                                                },
                                                      child:
                                                          const Text('Delete')),
                                                ]),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                ElevatedButton(
                                                    onPressed: () async {
                                                      setState(() {
                                                        createListErrorText =
                                                            null;
                                                        createListHelperText =
                                                            null;
                                                      });
                                                      final listName =
                                                          newCustimListNameController
                                                              .text;
                                                      if (listName.isEmpty) {
                                                        setState(() {
                                                          createListErrorText =
                                                              "Set the name of list";
                                                        });
                                                        return;
                                                      }
                                                      var listWithSameNameExists =
                                                          await CustomListSQL
                                                              .selectLocationByName(
                                                                  listName);
                                                      if (listWithSameNameExists !=
                                                          null) {
                                                        setState(() {
                                                          createListErrorText =
                                                              "List is already exists with same name";
                                                        });
                                                        return;
                                                      }
                                                      List<GameThing>
                                                          selectedGames =
                                                          getSelectedGames();
                                                      if (selectedGames
                                                          .isEmpty) {
                                                        setState(() {
                                                          createListErrorText =
                                                              "Chose games to create list";
                                                        });
                                                        return;
                                                      }
                                                      selectedGames.sort((a,
                                                              b) =>
                                                          a.id.compareTo(b.id));
                                                      final selectedGamesString =
                                                          selectedGames
                                                              .map((x) => x.id)
                                                              .join(";");
                                                      var someId = await CustomListSQL
                                                          .addCustomListByName(
                                                              listName,
                                                              selectedGamesString);
                                                      setState(() {
                                                        createListHelperText =
                                                            "List was created";
                                                      });
                                                      final customList =
                                                          await CustomListSQL
                                                              .selectCustomListById(
                                                                  someId);
                                                      if (customList == null) {
                                                        return;
                                                      }
                                                      gamesList[someId] =
                                                          listName;
                                                      chosenGameListId = someId;
                                                      await updateGamesFromCustomList(
                                                          chosenGameListId);
                                                      newCustimListNameController
                                                          .text = '';
                                                      setState(() {});
                                                    },
                                                    child:
                                                        const Text('Create')),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    child: TextField(
                                                        controller:
                                                            newCustimListNameController,
                                                        decoration: InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .fromLTRB(
                                                                    10,
                                                                    0,
                                                                    0,
                                                                    0),
                                                            helperText:
                                                                createListHelperText,
                                                            errorText:
                                                                createListErrorText,
                                                            labelText:
                                                                'List name')))
                                              ],
                                            ),
                                          ])),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                  child: SingleChildScrollView(
                                      child: Column(
                                          children: gamesFromFilter.map((game) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: Text(
                                          (game.keys.first).name,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                        CustomCounter(game, gamesFromFilter)
                                      ]),
                                );
                              }).toList())))
                            ]));
                          });
                        });
                  },
                  label: const Text('Filter'),
                  icon: const Icon(Icons.filter_alt),
                ))
          ]),
          // Row(
          //   children: [
          //     ElevatedButton(
          //         onPressed: () => {print('Create')},
          //         child: Text('Create list'))
          //   ],
          // )
        ),
        Flexible(
            flex: 1,
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: ElevatedButton(
                  onPressed: () async {
                    List<GameThing>? chosenGames = [];
                    if (gamesFromFilter
                        .any((element) => element.values.first > 0)) {
                      for (var gameFromFilter in gamesFromFilter) {
                        if (gameFromFilter.values.first > 0) {
                          for (var i = 0;
                              i < gameFromFilter.values.first;
                              i++) {
                            chosenGames.add(gameFromFilter.keys.first);
                          }
                        }
                      }
                    } else {
                      chosenGames = allGames;
                    }
                    List<GameThing> filteredGames = [];
                    if (chosenGames == null) return;
                    for (var game in chosenGames) {
                      if (isGameMatchChosenPlayersCount(
                          game, chosenPlayersCount, maxRangeValues)) {
                        if (onlyOwnedGames) {
                          if (game.owned == 0) continue;
                        }
                        filteredGames.add(game);
                      }
                    }
                    if (filteredGames.isEmpty) {
                      setState(() {
                        chosenGame = "No game with chosen players count";
                      });
                    } else {
                      setState(() {
                        chosenGame = ((filteredGames..shuffle()).first).name;
                      });
                    }
                  },
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.secondary),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: Colors.black12)))),
                  child: const Text("Choose random game"),
                ))),
        SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.1,
            child: FittedBox(
                child: Text(
              selectionColor: Colors.tealAccent,
              chosenGame,
              textAlign: TextAlign.center,
            ))),
      ])
    ])));
  }
}

bool isGameMatchChosenPlayersCount(
    GameThing game, double chosenPlayersCount, RangeValues maxRangeValues) {
  if (game.minPlayers == 0 && game.maxPlayers == 0) {
    return true;
  }

  if (game.minPlayers <= chosenPlayersCount.round() &&
      game.maxPlayers >= chosenPlayersCount.round() &&
      (maxRangeValues.end == 0 ||
          (maxRangeValues.end != 0 &&
              game.maxPlayers <= maxRangeValues.end &&
              game.maxPlayers >= maxRangeValues.start))) {
    return true;
  }
  return false;
}

class CustomCounter extends StatefulWidget {
  const CustomCounter(this.game, this.gamesFromFilter, {super.key});

  final Map<GameThing, int> game;
  final List<Map<GameThing, int>> gamesFromFilter;
  @override
  State<CustomCounter> createState() => _CustomCounterState();
}

class _CustomCounterState extends State<CustomCounter> {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      RawMaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
        onPressed: () {
          if (widget.game.values.first < 1) return;
          setState(() {
            widget.gamesFromFilter[widget.gamesFromFilter.indexOf(widget.game)]
                [widget.game.keys.first] = widget.game.values.first - 1;
          });
        },
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.remove,
          color: Colors.black,
          size: 12.0,
        ),
      ),
      Text(widget.game.values.first.toString()),
      RawMaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
        onPressed: () {
          setState(() {
            widget.gamesFromFilter[widget.gamesFromFilter.indexOf(widget.game)]
                [widget.game.keys.first] = widget.game.values.first + 1;
          });
        },
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 12.0,
        ),
      ),
    ]);
  }
}
