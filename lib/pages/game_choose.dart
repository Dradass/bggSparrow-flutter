import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import 'package:flutter_application_1/models/game_list_model.dart';
import '../db/game_things_sql.dart';
import '../db/game_list_sql.dart';
import 'dart:developer';
import '../globals.dart';
import '../s.dart';

class GameHelper extends StatefulWidget {
  const GameHelper({super.key});

  @override
  State<GameHelper> createState() => _GameHelperState();
}

class _GameHelperState extends State<GameHelper> {
  double chosenPlayersCount = 0;
  String? chosenGame;
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

  Future<void> updateCustomLists(dynamic context) async {
    GameListSQL.getAllGameLists().then((lists) {
      gamesList[0] = S.of(context).all;
      var customLists = (List.generate(
          lists.length, (index) => GameList.fromJson(lists[index])));
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
    var existedList = await GameListSQL.selectCustomListById(listId);
    if (existedList == null) {
      return false;
    }
    var newList = GameList(
        id: listId, name: existedList.name, value: selectedGamesString);
    GameListSQL.updateCustomList(newList);
    return true;
  }

  Future<void> updateGamesFromCustomList(int listId) async {
    if (chosenGameListId == 0) {
      await updateGamesToAll();
      setState(() {});
      return;
    }
    var customList = await GameListSQL.selectCustomListById(chosenGameListId);
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
    updateCustomLists(context);

    return SafeArea(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        // Flexible(
        //     flex: 1,
        //     child: SizedBox(
        //         width: MediaQuery.of(context).size.width,
        //         height: MediaQuery.of(context).size.height,
        //         child: const Text(" "))),
        SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.2,
            child: FittedBox(
                child: ValueListenableBuilder<bool>(
              valueListenable: isLoadedGamesPlayersCountInfoNotifier,
              builder: (context, value, _) {
                return value
                    ? Container()
                    : Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          maxLines: 2,
                          value
                              ? ""
                              : "*${S.of(context).gamePlayersInfoNotLoaded}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            backgroundColor: Colors.transparent,
                          ),
                        ));
              },
            ))),
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
                    Text(S.of(context).maxPlayersCount),
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
                      min: 0,
                      max: 12,
                      divisions: 12,
                      label: chosenPlayersCount.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          chosenPlayersCount = value;
                        });
                      },
                    ),
                    Text(S.of(context).playersCount),
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
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  label: SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 1,
                      child: Text(
                        S.of(context).onlyOwnedGames,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      )),
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
                    await updateCustomLists(context);
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
                                  Container(
                                      color: Colors.red,
                                      width: MediaQuery.of(context).size.width *
                                          0.4,
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
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary)),
                                          child: Text(
                                              S.of(context).showAllGames))),
                                  Row(children: [
                                    Text(S.of(context).votes),
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
                                          shape: const Border(),
                                          textColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          iconColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          collapsedIconColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          collapsedTextColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          title: Text(
                                            S.of(context).gamesLists,
                                          ),
                                          children: [
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(children: [
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
                                                                        createListErrorText = S
                                                                            .of(context)
                                                                            .cantUpdateThisListTryAgain;
                                                                      });
                                                                      return;
                                                                    }
                                                                    setState(
                                                                        () {});
                                                                    setState(
                                                                        () {
                                                                      createListHelperText = S
                                                                          .of(context)
                                                                          .listWasUpdated;
                                                                    });
                                                                  },
                                                        style: ButtonStyle(
                                                            backgroundColor: WidgetStateProperty
                                                                .all(Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .secondary)),
                                                        child: Text(S
                                                            .of(context)
                                                            .update)),
                                                    DropdownButton(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
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
                                                  ]),
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
                                                                      await GameListSQL
                                                                          .selectCustomListById(
                                                                              chosenGameListId);
                                                                  if (customList ==
                                                                      null) {
                                                                    return;
                                                                  }
                                                                  GameListSQL
                                                                      .deleteCustomList(
                                                                          customList);
                                                                  gamesList.remove(
                                                                      customList
                                                                          .id);
                                                                  setState(
                                                                      () {});
                                                                  setState(() {
                                                                    createListHelperText = S
                                                                        .of(context)
                                                                        .listWasDeleted;
                                                                  });
                                                                },
                                                      style: ButtonStyle(
                                                          backgroundColor:
                                                              WidgetStateProperty
                                                                  .all(Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .secondary)),
                                                      child: Text(S
                                                          .of(context)
                                                          .delete)),
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
                                                          createListErrorText = S
                                                              .of(context)
                                                              .setTheListName;
                                                        });
                                                        return;
                                                      }
                                                      var listWithSameNameExists =
                                                          await GameListSQL
                                                              .selectLocationByName(
                                                                  listName);
                                                      if (listWithSameNameExists !=
                                                          null) {
                                                        setState(() {
                                                          createListErrorText = S
                                                              .of(context)
                                                              .listIsAlreadyExistsWithSameName;
                                                        });
                                                        return;
                                                      }
                                                      List<GameThing>
                                                          selectedGames =
                                                          getSelectedGames();
                                                      if (selectedGames
                                                          .isEmpty) {
                                                        setState(() {
                                                          createListErrorText = S
                                                              .of(context)
                                                              .pickTheGamesToCreateList;
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
                                                      var someId = await GameListSQL
                                                          .addCustomListByName(
                                                              listName,
                                                              selectedGamesString);
                                                      setState(() {
                                                        createListHelperText = S
                                                            .of(context)
                                                            .listWasCreated;
                                                      });
                                                      final customList =
                                                          await GameListSQL
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
                                                      isSystemDropDownItem =
                                                          chosenGameListId == 0
                                                              ? true
                                                              : false;
                                                      setState(() {});
                                                    },
                                                    style: ButtonStyle(
                                                        backgroundColor:
                                                            WidgetStateProperty
                                                                .all(Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .secondary)),
                                                    child: Text(
                                                        S.of(context).create)),
                                                SizedBox(
                                                    width: MediaQuery.of(context).size.width *
                                                        0.4,
                                                    child: TextField(
                                                        controller:
                                                            newCustimListNameController,
                                                        decoration: InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            contentPadding:
                                                                const EdgeInsets.fromLTRB(
                                                                    10, 0, 0, 0),
                                                            helperText:
                                                                createListHelperText,
                                                            helperStyle: TextStyle(
                                                                color: Theme.of(context)
                                                                    .colorScheme
                                                                    .primary),
                                                            errorText:
                                                                createListErrorText,
                                                            labelText: S
                                                                .of(context)
                                                                .listName,
                                                            labelStyle: TextStyle(
                                                                color: Theme.of(context)
                                                                    .colorScheme
                                                                    .primary))))
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
                                          child: Tooltip(
                                            message: (game.keys.first).name,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  gamesFromFilter[
                                                              gamesFromFilter
                                                                  .indexOf(
                                                                      game)]
                                                          [game.keys.first] =
                                                      game.values.first + 1;
                                                });
                                              },
                                              child: Text(
                                                (game.keys.first).name,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                        CustomCounter(game, gamesFromFilter)
                                      ]),
                                );
                              }).toList())))
                            ]));
                          });
                        });
                  },
                  label: Text(S.of(context).filters),
                  icon: const Icon(Icons.filter_alt),
                ))
          ]),
        ),
        Flexible(
            flex: 1,
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: ElevatedButton(
                  onPressed: () async {
                    await updateGamesFromCustomList(chosenGameListId);
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
                        chosenGame =
                            S.of(context).gameNotFoundMatchingYourConditions;
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
                  child: Text(S.of(context).chooseRandomGame),
                ))),
        SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.1,
            child: FittedBox(
                child: Text(
              selectionColor: Colors.tealAccent,
              chosenGame ?? S.of(context).chooseAnyGame,
              textAlign: TextAlign.center,
            ))),
      ])
    ]));
  }
}

bool isGameMatchChosenPlayersCount(
    GameThing game, double chosenPlayersCount, RangeValues maxRangeValues) {
  if ((game.minPlayers == 0 && game.maxPlayers == 0) ||
      chosenPlayersCount == 0) {
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
        child: Icon(
          Icons.remove,
          color: Theme.of(context).colorScheme.primary,
          size: 12.0,
        ),
      ),
      Text(
        widget.game.values.first.toString(),
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
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
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
          size: 12.0,
        ),
      ),
    ]);
  }
}
