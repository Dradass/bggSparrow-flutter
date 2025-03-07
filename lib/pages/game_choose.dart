import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import '../db/game_things_sql.dart';

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
  final SearchController searchController = SearchController();

  @override
  Widget build(BuildContext context) {
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
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                          var allGames = await GameThingSQL.getAllGames();
                          if (allGames == null) {
                            print("No games");
                            return;
                          }
                          allGames.sort((a, b) => a.name.compareTo(b.name));
                          gamesFromFilter.clear();
                          for (var game in allGames) {
                            if (onlyOwnedGames) {
                              if (game.owned == 0) continue;
                            }
                            if (isGameMatchChosenPlayersCount(
                                game, chosenPlayersCount, maxRangeValues)) {
                              gamesFromFilter.add({game: game.owned});
                            }
                          }
                          showDialog(
                              context: context,
                              builder: (BuildContext) {
                                return StatefulBuilder(
                                    builder: (context, setState) {
                                  return AlertDialog(
                                      content: Column(children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Game'),
                                        Container(
                                            color: Colors.red,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                            child: ElevatedButton(
                                                onPressed: () {
                                                  for (var gameFromFilter
                                                      in gamesFromFilter) {
                                                    var game = gameFromFilter
                                                        .keys.first;
                                                    gameFromFilter.update(
                                                        game,
                                                        (value2) =>
                                                            game.owned == 1
                                                                ? value2 = 1
                                                                : 0);
                                                  }
                                                  setState(() {});
                                                },
                                                child:
                                                    const Text("Only owned"))),
                                        Row(children: [
                                          const Text('Votes'),
                                          Checkbox(
                                              value: gamesFilterNeedClear == 1,
                                              onChanged: ((value) {
                                                for (var gameFromFilter
                                                    in gamesFromFilter) {
                                                  gameFromFilter.update(
                                                      gameFromFilter.keys.first,
                                                      (value2) => value2 =
                                                          value! ? 1 : 0);
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
                                    const Divider(),
                                    Expanded(
                                        child: SingleChildScrollView(
                                            child: Column(
                                                children:
                                                    gamesFromFilter.map((game) {
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
                                              CustomCounter(
                                                  game, gamesFromFilter)
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
                ])),
        Flexible(
            flex: 1,
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: ElevatedButton(
                  onPressed: () async {
                    List<GameThing>? allGames = [];
                    if (gamesFromFilter
                        .any((element) => element.values.first > 0)) {
                      for (var gameFromFilter in gamesFromFilter) {
                        if (gameFromFilter.values.first > 0) {
                          for (var i = 0;
                              i < gameFromFilter.values.first;
                              i++) {
                            allGames.add(gameFromFilter.keys.first);
                          }
                        }
                      }
                    } else {
                      allGames = await GameThingSQL.getAllGames();
                    }
                    List<GameThing> filteredGames = [];
                    if (allGames == null) return;
                    for (var game in allGames) {
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
  CustomCounter(this.game, this.gamesFromFilter, {super.key});

  Map<GameThing, int> game;
  List<Map<GameThing, int>> gamesFromFilter = [];
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
