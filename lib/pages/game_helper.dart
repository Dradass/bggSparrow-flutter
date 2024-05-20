import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import '../db/game_things_sql.dart';
import 'dart:convert';

class GameHelper extends StatefulWidget {
  const GameHelper({super.key});

  @override
  State<GameHelper> createState() => _GameHelperState();
}

class _GameHelperState extends State<GameHelper> {
  double minPlayersValue = 1;
  double maxPlayersValue = 4;
  double chosenPlayersCount = 4;
  String chosenGame = "Get some random game";
  RangeValues minRangeValues = const RangeValues(1, 4);
  RangeValues maxRangeValues = const RangeValues(0, 0);
  bool onlyOwnedGames = true;
  bool gamesFilterNeedClear = false;
  List<Map<GameThing, bool>> gamesFromFilter = [];
  List<Map<GameThing, bool>> allItems = [];
  List<Map<GameThing, bool>> items = [];
  final SearchController searchController = SearchController();

  void queryListener() {
    search(searchController.text);
  }

  void search(String query) {
    if (query.isEmpty) {
      setState(() {
        items = allItems;
      });
    } else {
      setState(() {
        items = allItems
            .where((e) =>
                e.keys.first.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Game helper"),
          centerTitle: true,
        ),
        body: SafeArea(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
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
                                height:
                                    MediaQuery.of(context).size.height * 0.03,
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
                              //games = ;
                              var allGames = await GameThingSQL.getAllGames();
                              if (allGames == null) {
                                print("No games");
                                return;
                              }
                              allGames.sort((a, b) => a.name.compareTo(b.name));
                              if (gamesFromFilter.isEmpty) {
                                for (var game in allGames) {
                                  gamesFromFilter.add({game: game.owned == 1});
                                }
                              }
                              print(gamesFromFilter);
                              print('filter');
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
                                            Checkbox(
                                                value: gamesFilterNeedClear,
                                                onChanged: ((value) {
                                                  print('value = $value');
                                                  for (var gameFromFilter
                                                      in gamesFromFilter) {
                                                    print(
                                                        'updated ${gameFromFilter.keys.first.name}');
                                                    print(gameFromFilter
                                                        .values.first);
                                                    gameFromFilter.update(
                                                        gameFromFilter
                                                            .keys.first,
                                                        (value2) =>
                                                            value2 = value!);
                                                    print(gameFromFilter
                                                        .values.first);
                                                  }
                                                  setState(
                                                    () {
                                                      print(value);
                                                      gamesFilterNeedClear =
                                                          value!;
                                                    },
                                                  );
                                                })),
                                          ],
                                        ),
                                        Divider(),
                                        Expanded(
                                            child: SingleChildScrollView(
                                                child: Column(
                                                    children: gamesFromFilter
                                                        .map((game) {
                                          return CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  //SizedBox(width: 10),
                                                  Expanded(
                                                      child: Text(
                                                    (game.keys.first
                                                            as GameThing)
                                                        .name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ))
                                                ]),
                                            value: game.values.first,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                gamesFromFilter[gamesFromFilter
                                                        .indexOf(game)]
                                                    [game.keys.first] = value!;
                                              });
                                            },
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
                        if (gamesFromFilter.isNotEmpty) {
                          allGames = gamesFromFilter
                              .where((element) => element.values.first == true)
                              .map((e) => e.keys.first)
                              .toList();
                        } else {
                          allGames = await GameThingSQL.getAllGames();
                        }
                        print(allGames!.length);
                        List<GameThing> filteredGames = [];
                        if (allGames == null) return;
                        print(allGames.length);
                        print(chosenPlayersCount);
                        for (var game in allGames) {
                          // print(
                          //     "Game = ${game.name}, min = ${game.minPlayers}, max = ${game.maxPlayers}");
                          if (game.minPlayers <= chosenPlayersCount.round() &&
                              game.maxPlayers >= chosenPlayersCount.round() &&
                              (maxRangeValues.end == 0 ||
                                  (maxRangeValues.end != 0 &&
                                      game.maxPlayers <= maxRangeValues.end &&
                                      game.maxPlayers >=
                                          maxRangeValues.start))) {
                            if (onlyOwnedGames!) {
                              if (game.owned == 0) continue;
                            }
                            // if (gamesFromFilter
                            //     .where(
                            //         (element) => element.values.first == true)
                            //     .contains(game))
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
                            chosenGame =
                                ((filteredGames..shuffle()).first).name;
                          });
                        }
                      },
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                      side:
                                          BorderSide(color: Colors.black12)))),
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
