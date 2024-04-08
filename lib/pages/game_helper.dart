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
  double chosenPlayersCount = 4;
  String chosenGame = "No game was chosen";
  RangeValues minRangeValues = const RangeValues(1, 4);
  RangeValues maxRangeValues = const RangeValues(0, 0);
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
            Checkbox(
              value: onlyOwnedGames,
              onChanged: (bool? value) {
                setState(() {
                  onlyOwnedGames = value;
                });
              },
            ),
            ElevatedButton(
              child: const Text("Choose random game"),
              onPressed: () async {
                var allGames = await GameThingSQL.getAllGames();
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
                              game.maxPlayers >= maxRangeValues.start))) {
                    if (onlyOwnedGames!) {
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
            ),
            Text(chosenGame),
          ])
        ])));
  }
}
