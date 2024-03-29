import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/game_thing.dart';
import '../db/game_things_sql.dart';

class GameHelper extends StatefulWidget {
  const GameHelper({super.key});

  @override
  State<GameHelper> createState() => _GameHelperState();
}

class _GameHelperState extends State<GameHelper> {
  double minPlayersValue = 1;
  double maxPlayersValue = 4;
  String chosenGame = "No game was chosen";
  double chosenPlayersCount = 4;
  RangeValues maxPlayersRangeValues = const RangeValues(0, 0);
  bool? onlyOwnedGames = true;
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
                child: Container(
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
            Flexible(
                flex: 1,
                child: Container(
                    //color: Colors.blueAccent,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      children: [
                        RangeSlider(
                          values: maxPlayersRangeValues,
                          max: 12,
                          divisions: 12,
                          labels: RangeLabels(
                            maxPlayersRangeValues.start.round().toString(),
                            maxPlayersRangeValues.end.round().toString(),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              maxPlayersRangeValues = values;
                            });
                          },
                        ),
                        const Text("Maximum players limit"),
                      ],
                    ))),
            Checkbox(
              value: onlyOwnedGames,
              onChanged: (bool? value) {
                setState(() {
                  onlyOwnedGames = value;
                });
              },
            ),
            ElevatedButton(
              child: Text("Chose game"),
              onPressed: () async {
                // if (maxPlayersCount < chosenPlayersCount &&
                //     maxPlayersCount != 0)
                //   setState(() {
                //     maxPlayersCount = chosenPlayersCount;
                //   });
                var allGames = await GameThingSQL.getAllGames();
                List<GameThing> filteredGames = [];
                if (allGames == null) return;
                for (var game in allGames) {
                  print(
                      "Game = ${game.name}, min = ${game.minPlayers}, max = ${game.maxPlayers}");

                  if (game.minPlayers <= chosenPlayersCount &&
                          game.maxPlayers >= chosenPlayersCount &&
                          maxPlayersRangeValues.end != 0
                      ? game.maxPlayers <= maxPlayersRangeValues.end
                      : true && maxPlayersRangeValues.start != 0
                          ? game.maxPlayers >= maxPlayersRangeValues.start
                          : true) {
                    if (onlyOwnedGames!) {
                      if (game.owned == 0) continue;
                    }
                    filteredGames.add(game);
                  }
                  if (filteredGames.isEmpty) {
                    setState(() {
                      chosenGame = "No game with chosen players count";
                    });
                  } else {
                    print(filteredGames);
                    setState(() {
                      chosenGame = ((filteredGames..shuffle()).first).name;
                    });
                  }
                }
              },
            ),
            Flexible(
                flex: 1,
                child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Expanded(
                        child: Text(
                      chosenGame,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 30),
                    )))),
          ])
        ])));
  }
}
