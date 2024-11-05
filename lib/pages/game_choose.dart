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
  // List<Map<GameThing, int>> items = [];
  final SearchController searchController = SearchController();

  // void queryListener() {
  //   search(searchController.text);
  // }

  // void search(String query) {
  //   if (query.isEmpty) {
  //     setState(() {
  //       items = allItems;
  //     });
  //   } else {
  //     setState(() {
  //       items = allItems
  //           .where((e) =>
  //               e.keys.first.name.toLowerCase().contains(query.toLowerCase()))
  //           .toList();
  //     });
  //   }
  // }

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
                //color: Colors.blueAccent,
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
                //color: Colors.blueAccent,
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
                  Container(
                      //color: Colors.brown,
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: double.maxFinite,
                      child: ChoiceChip(
                        label: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.03,
                            child: Text("Only owned games")),
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
                                        Text('Game'),
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
                                                child: Text("Only owned"))),
                                        Row(children: [
                                          Text('Votes'),
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
                                    Divider(),
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
                                              //SizedBox(width: 10),
                                              Expanded(
                                                  child: Text(
                                                (game.keys.first as GameThing)
                                                    .name,
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
                        label: Text('Filter'),
                        icon: Icon(Icons.filter_alt),
                      ))
                ])),
        Flexible(
            flex: 1,
            child: SizedBox(
                //color: Colors.blueAccent,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: ElevatedButton(
                  child: const Text("Choose random game"),
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
                      // print(
                      //     "Game = ${game.name}, min = ${game.minPlayers}, max = ${game.maxPlayers}");
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
                      for (var game in filteredGames) {
                        print(
                            "Game = ${game.name}, min = ${game.minPlayers}, max = ${game.maxPlayers}");
                      }
                      setState(() {
                        chosenGame = ((filteredGames..shuffle()).first).name;
                      });
                    }
                  },
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: Colors.black12)))),
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
  CustomCounter(this.game, this.gamesFromFilter);

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
        constraints: BoxConstraints(minWidth: 32.0, minHeight: 32.0),
        onPressed: () {
          if (widget.game.values.first < 1) return;
          setState(() {
            widget.gamesFromFilter[widget.gamesFromFilter.indexOf(widget.game)]
                [widget.game.keys.first] = widget.game.values.first - 1;
          });
        },
        elevation: 2.0,
        //fillColor: Colors.grey,
        child: Icon(
          Icons.remove,
          color: Colors.black,
          size: 12.0,
        ),
        shape: CircleBorder(),
      ),
      Text(widget.game.values.first.toString()),
      RawMaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        constraints: BoxConstraints(minWidth: 32.0, minHeight: 32.0),
        onPressed: () {
          setState(() {
            widget.gamesFromFilter[widget.gamesFromFilter.indexOf(widget.game)]
                [widget.game.keys.first] = widget.game.values.first + 1;
          });
        },
        elevation: 2.0,
        //fillColor: Colors.grey,
        child: Icon(
          Icons.add,
          color: Colors.black,
          size: 12.0,
        ),
        shape: CircleBorder(),
      ),
    ]);
  }
}
