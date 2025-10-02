import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/bgg_play_player.dart';

import '../db/players_list_sql.dart';
import '../models/player_list_model.dart';
import '../db/players_sql.dart';
import '../bggApi/bgg_api.dart';
import 'dart:developer';
import '../s.dart';

class PlayersListWrapper {
  String? sourcePlayers;
  String? listManageErrorText;
  String? listManageHintText;
  bool isSystemDropDownItem = true;
  int chosenPlayersListId = 0;
  List<Map> players = [];
  Map<int, String> playersList = {};
  final newListNameController = TextEditingController();

  Future<void> updateCustomLists(dynamic context) async {
    PlayerListSQL.getAllPlayerLists().then((lists) {
      playersList[0] = S.of(context).all;
      var customLists = (List.generate(
          lists.length, (index) => PlayersList.fromJson(lists[index])));
      if (customLists.isEmpty) return;
      for (var customList in customLists) {
        playersList[customList.id] = customList.name;
      }
    });
  }

  Future<void> updatePlayersFromCustomList() async {
    if (chosenPlayersListId == 0) {
      players = await PlayersSQL.getAllPlayers();

// Fill players marks
      if (sourcePlayers != null && sourcePlayers != "") {
        var sourceBggPlayers =
            sourcePlayers!.split(";").map((e) => BggPlayPlayer.fromString(e));
        for (var player in players) {
          if (player['userid'] != 0) {
            var matchedPlayer = sourceBggPlayers
                .where(
                    (element) => element.userid == player['userid'].toString())
                .firstOrNull;
            if (matchedPlayer != null) {
              player['isChecked'] = true;
              if (matchedPlayer.win == "1") {
                player['win'] = true;
              }
            }
          } else {
            var matchedPlayer = sourceBggPlayers
                .where((element) => element.name == player['name'])
                .firstOrNull;
            if (matchedPlayer != null) {
              player['isChecked'] = true;
              if (matchedPlayer.win == "1") {
                player['win'] = true;
              }
            }
          }
        }
      }
      players.sort((a, b) => a['name'].compareTo(b['name']));

      return;
    }
    var customList =
        await PlayerListSQL.selectCustomListById(chosenPlayersListId);
    if (customList != null) {
      var playersString = customList.value;
      if (playersString != null) {
        var playersList = playersString.split(';');
        players.clear();
        for (var playerId in playersList) {
          var player = await PlayersSQL.selectPlayerById(int.parse(playerId));
          if (player != null) {
            players.add({
              'username': player.username,
              'userid': player.userid,
              'name': player.name,
              'startPosition': player.startposition ?? "0",
              'color': player.color ?? "0",
              'score': player.score ?? "0",
              'new': player.isNew ?? "0",
              'rating': player.rating ?? "0",
              'win': false,
              'id': player.id,
              'isChecked': false,
              'excluded': false,
            });
          } else {
            log('Cant find player with id $playerId');
          }
        }
        // Fill players marks
        if (sourcePlayers != null && sourcePlayers != "") {
          var sourceBggPlayers =
              sourcePlayers!.split(";").map((e) => BggPlayPlayer.fromString(e));
          for (var player in players) {
            if (player['userid'] != 0) {
              var matchedPlayer = sourceBggPlayers
                  .where((element) =>
                      element.userid == player['userid'].toString())
                  .firstOrNull;
              if (matchedPlayer != null) {
                player['isChecked'] = true;
                if (matchedPlayer.win == "1") {
                  player['win'] = true;
                }
              }
            } else {
              var matchedPlayer = sourceBggPlayers
                  .where((element) => element.name == player['name'])
                  .firstOrNull;
              if (matchedPlayer != null) {
                player['isChecked'] = true;
                if (matchedPlayer.win == "1") {
                  player['win'] = true;
                }
              }
            }
          }
        }
        players.sort((a, b) => a['name'].compareTo(b['name']));
      }
    }
  }

  List<BggPlayPlayer> getBggPlayers() {
    List<BggPlayPlayer> result = [];
    for (var player in players) {
      var bggPlayer = BggPlayPlayer(
          username: player['username'],
          userid: player['userid'].toString(),
          name: player['name'],
          startposition: player['startPosition'],
          color: player['color'],
          score: player['score'],
          isNew: player['new'],
          rating: player['rating'],
          win: player['win'] ? "1" : "0");
      result.add(bggPlayer);
    }
    return result;
  }
}

List<Map> getSelectedPlayers(List<Map> players) {
  List<Map> selectedPlayers = [];
  for (var player in players) {
    if (player['isChecked']) {
      selectedPlayers.add(player);
    }
  }
  return selectedPlayers;
}

Future<bool> updateCustomPlayersList(
    List<int> selectedPlayersIds, int listId) async {
  selectedPlayersIds.sort((a, b) => a.compareTo(b));
  final selectedGamesString = selectedPlayersIds.join(";");
  var existedList = await PlayerListSQL.selectCustomListById(listId);
  if (existedList == null) {
    return false;
  }
  var newList = PlayersList(
      id: listId, name: existedList.name, value: selectedGamesString);
  PlayerListSQL.updateCustomList(newList);
  return true;
}

class UpdateButton extends StatefulWidget {
  UpdateButton(
      {super.key,
      required this.playersListWrapper,
      required this.parentStateUpdate});
  PlayersListWrapper playersListWrapper;
  dynamic parentStateUpdate;

  @override
  State<UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<UpdateButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: widget.playersListWrapper.isSystemDropDownItem
            ? null
            : () async {
                widget.playersListWrapper.listManageErrorText = null;
                widget.playersListWrapper.listManageHintText = null;
                widget.parentStateUpdate();
                var selectedPlayers =
                    getSelectedPlayers(widget.playersListWrapper.players)
                        .map((x) => x['id'] as int)
                        .toList();
                if (!await updateCustomPlayersList(selectedPlayers,
                    widget.playersListWrapper.chosenPlayersListId)) {
                  widget.playersListWrapper.listManageErrorText =
                      S.of(context).cantUpdateThisListTryAgain;
                  widget.parentStateUpdate();
                  return;
                }
                widget.playersListWrapper.listManageHintText =
                    S.of(context).listWasUpdated;
                await widget.playersListWrapper.updatePlayersFromCustomList();
                widget.parentStateUpdate();
              },
        child: Text(S.of(context).update));
  }
}

class DeleteButton extends StatefulWidget {
  DeleteButton(
      {super.key,
      required this.playersListWrapper,
      required this.parentStateUpdate});

  PlayersListWrapper playersListWrapper;
  dynamic parentStateUpdate;

  @override
  State<DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<DeleteButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: widget.playersListWrapper.isSystemDropDownItem
            ? null
            : () async {
                widget.playersListWrapper.listManageErrorText = null;
                widget.playersListWrapper.listManageHintText = null;
                widget.parentStateUpdate();
                final customList = await PlayerListSQL.selectCustomListById(
                    widget.playersListWrapper.chosenPlayersListId);
                if (customList == null) {
                  return;
                }
                PlayerListSQL.deleteCustomList(customList);
                widget.playersListWrapper.playersList.remove(customList.id);
                widget.playersListWrapper.chosenPlayersListId -= 1;
                widget.playersListWrapper.listManageHintText =
                    S.of(context).listWasDeleted;
                widget.parentStateUpdate();
              },
        child: Text(S.of(context).delete));
  }
}

class ChooseListDropdown extends StatefulWidget {
  ChooseListDropdown(
      {super.key,
      required this.playersListWrapper,
      required this.parentStateUpdate});

  PlayersListWrapper playersListWrapper;
  dynamic parentStateUpdate;

  @override
  State<ChooseListDropdown> createState() => _ChooseListDropdownState();
}

class _ChooseListDropdownState extends State<ChooseListDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      padding: const EdgeInsets.all(10),
      value: widget.playersListWrapper.playersList.isNotEmpty
          ? widget.playersListWrapper
              .playersList[widget.playersListWrapper.chosenPlayersListId]
          : null,
      onChanged: (String? value) async {
        widget.playersListWrapper.chosenPlayersListId = widget
            .playersListWrapper.playersList.entries
            .firstWhere((entry) => entry.value == value)
            .key;
        widget.playersListWrapper.isSystemDropDownItem =
            widget.playersListWrapper.chosenPlayersListId == 0 ? true : false;

        await widget.playersListWrapper.updatePlayersFromCustomList();
        widget.parentStateUpdate();
      },
      items: widget.playersListWrapper.playersList.values
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
  }
}

class CreateButton extends StatefulWidget {
  CreateButton(
      {super.key,
      required this.playersListWrapper,
      required this.parentStateUpdate});

  PlayersListWrapper playersListWrapper;
  dynamic parentStateUpdate;

  @override
  State<CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<CreateButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () async {
          widget.playersListWrapper.listManageErrorText = null;
          widget.playersListWrapper.listManageHintText = null;
          widget.parentStateUpdate();
          final listName = widget.playersListWrapper.newListNameController.text;
          if (listName.isEmpty) {
            widget.playersListWrapper.listManageErrorText =
                S.of(context).setTheListName;
            widget.parentStateUpdate();
            return;
          }

          var listWithSameNameExists =
              await PlayerListSQL.selectLocationByName(listName);
          if (listWithSameNameExists != null) {
            widget.playersListWrapper.listManageErrorText =
                S.of(context).listIsAlreadyExistsWithSameName;
            widget.parentStateUpdate();
            return;
          }
          List<Map> selectedPlayers =
              getSelectedPlayers(widget.playersListWrapper.players);
          if (selectedPlayers.isEmpty) {
            widget.playersListWrapper.listManageErrorText =
                S.of(context).pickThePlayersToCreateList;
            widget.parentStateUpdate();
            return;
          }

          selectedPlayers.sort((a, b) => a['id'].compareTo(b['id']));
          final selectedPlayersIdsString =
              selectedPlayers.map((x) => x['id']).join(";");

          var listId = await PlayerListSQL.addCustomListByName(
              listName, selectedPlayersIdsString);
          widget.playersListWrapper.listManageHintText =
              S.of(context).listWasCreated;
          widget.parentStateUpdate();
          final customList = await PlayerListSQL.selectCustomListById(listId);

          if (customList == null) {
            return;
          }

          //
          widget.playersListWrapper.playersList[listId] = listName;
          widget.playersListWrapper.chosenPlayersListId = listId;
          await widget.playersListWrapper.updatePlayersFromCustomList();
          widget.playersListWrapper.newListNameController.text = '';
          widget.playersListWrapper.isSystemDropDownItem =
              widget.playersListWrapper.chosenPlayersListId == 0 ? true : false;
          widget.parentStateUpdate();
        },
        child: Text(S.of(context).create));
  }
}

class ShowAllPlayersButton extends StatefulWidget {
  ShowAllPlayersButton(
      {super.key,
      required this.playersListWrapper,
      required this.parentStateUpdate});

  PlayersListWrapper playersListWrapper;
  dynamic parentStateUpdate;

  @override
  State<ShowAllPlayersButton> createState() => _ShowAllPlayersButtonState();
}

class _ShowAllPlayersButtonState extends State<ShowAllPlayersButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        label: const Text(''),
        onPressed: () async {
          widget.playersListWrapper.players = await getAllPlayers();

          var customList = await PlayerListSQL.selectCustomListById(
              widget.playersListWrapper.chosenPlayersListId);
          if (customList != null) {
            var playersString = customList.value;
            if (playersString != null && playersString.isNotEmpty) {
              var playersList = playersString.split(';');
              for (var playerId in playersList) {
                for (var player in widget.playersListWrapper.players) {
                  if (player['id'] == int.parse(playerId)) {
                    player['isChecked'] = true;
                  }
                }
              }
            }
          }
          widget.parentStateUpdate();
        },
        icon: const Icon(Icons.remove_red_eye_outlined));
  }
}

class ListNameField extends StatefulWidget {
  ListNameField({super.key, required this.playersListWrapper});

  PlayersListWrapper playersListWrapper;

  @override
  State<ListNameField> createState() => _ListNameFieldState();
}

class _ListNameFieldState extends State<ListNameField> {
  @override
  Widget build(BuildContext context) {
    widget.playersListWrapper.listManageErrorText = null;
    widget.playersListWrapper.listManageHintText = null;
    return TextField(
        controller: widget.playersListWrapper.newListNameController,
        decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            helperText: widget.playersListWrapper.listManageHintText,
            errorText: widget.playersListWrapper.listManageErrorText,
            labelText: S.of(context).listName));
  }
}
