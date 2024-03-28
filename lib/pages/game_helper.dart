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
  RangeValues minRangeValues = const RangeValues(1, 4);
  RangeValues maxRangeValues = const RangeValues(1, 4);
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
                        RangeSlider(
                          values: minRangeValues,
                          max: 10,
                          divisions: 10,
                          labels: RangeLabels(
                              minRangeValues.start.round().toString(),
                              minRangeValues.end.round().toString()),
                          onChanged: (RangeValues values) {
                            setState(() {
                              minRangeValues = values;
                            });
                          },
                        ),
                        const Text("Min players count"),
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
            ElevatedButton(
              child: Text("Chose game"),
              onPressed: () async {
                var allGames = await GameThingSQL.getAllGames();
                List<GameThing> filteredGames = [];
                if (allGames == null) return;
                for (var game in allGames) {
                  print(
                      "Game = ${game.name}, min = ${game.minPlayers}, max = ${game.maxPlayers}");
                  if (game.minPlayers >= minRangeValues.start.round() &&
                      game.minPlayers <= minRangeValues.end.round() &&
                      game.maxPlayers >= maxRangeValues.start.round() &&
                      game.maxPlayers <= maxRangeValues.end.round()) {
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
            Text(chosenGame),
          ])
        ])));
  }
}
