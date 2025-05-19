import 'package:flutter/material.dart';

import '../db/players_list_sql.dart';
import '../models/player_list_model.dart';
import '../db/players_sql.dart';
import '../bggApi/bgg_api.dart';
import 'dart:developer';

class PlayersListWrapper {
  String? listManageErrorText;
  String? listManageHintText;
  bool isSystemDropDownItem = true;
  int chosenPlayersListId = 0;
  List<Map> players = [];
  Map<int, String> playersList = {};
  final newListNameController = TextEditingController();
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

Future<void> updatePlayersFromCustomList(
    PlayersListWrapper playersListWrapper) async {
  if (playersListWrapper.chosenPlayersListId == 0) {
    playersListWrapper.players = await PlayersSQL.getAllPlayers();
    return;
  }
  var customList = await PlayerListSQL.selectCustomListById(
      playersListWrapper.chosenPlayersListId);
  if (customList != null) {
    var playersString = customList.value;
    if (playersString != null) {
      var playersList = playersString.split(';');
      playersListWrapper.players.clear();
      for (var playerId in playersList) {
        var player = await PlayersSQL.selectPlayerById(int.parse(playerId));
        if (player != null) {
          playersListWrapper.players.add({
            'name': player.name,
            'id': player.id,
            'isChecked': false,
            'win': false,
            'excluded': false,
            'username': player.username,
            'userid': player.userid
          });
        } else {
          log('Cant find player with id $playerId');
        }
      }
      playersListWrapper.players.sort((a, b) => a['id'].compareTo(b['id']));
    }
  }
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
                      "Cant update this list";
                  widget.parentStateUpdate();
                  return;
                }
                widget.playersListWrapper.listManageHintText =
                    "List was updated";
                await updatePlayersFromCustomList(widget.playersListWrapper);
                widget.parentStateUpdate();
              },
        child: Text("Update"));
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
                    "List was deleted";
                widget.parentStateUpdate();
              },
        child: const Text("Delete"));
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

        await updatePlayersFromCustomList(widget.playersListWrapper);
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
                "Set the name of list";
            widget.parentStateUpdate();
            return;
          }

          var listWithSameNameExists =
              await PlayerListSQL.selectLocationByName(listName);
          if (listWithSameNameExists != null) {
            widget.playersListWrapper.listManageErrorText =
                "List is already exists with same name";
            widget.parentStateUpdate();
            return;
          }
          List<Map> selectedPlayers =
              getSelectedPlayers(widget.playersListWrapper.players);
          if (selectedPlayers.isEmpty) {
            widget.playersListWrapper.listManageErrorText =
                "Chose games to create list";
            widget.parentStateUpdate();
            return;
          }

          selectedPlayers.sort((a, b) => a['id'].compareTo(b['id']));
          final selectedPlayersIdsString =
              selectedPlayers.map((x) => x['id']).join(";");

          var listId = await PlayerListSQL.addCustomListByName(
              listName, selectedPlayersIdsString);
          widget.playersListWrapper.listManageHintText = "List was created";
          widget.parentStateUpdate();
          final customList = await PlayerListSQL.selectCustomListById(listId);

          if (customList == null) {
            return;
          }

          //
          widget.playersListWrapper.playersList[listId] = listName;
          widget.playersListWrapper.chosenPlayersListId = listId;
          await updatePlayersFromCustomList(widget.playersListWrapper);
          widget.playersListWrapper.newListNameController.text = '';
          widget.playersListWrapper.isSystemDropDownItem =
              widget.playersListWrapper.chosenPlayersListId == 0 ? true : false;
          widget.parentStateUpdate();
        },
        child: const Text("Create"));
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
        label: Text(''),
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
    return TextField(
        controller: widget.playersListWrapper.newListNameController,
        decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            helperText: widget.playersListWrapper.listManageHintText,
            errorText: widget.playersListWrapper.listManageErrorText,
            labelText: 'List name'));
  }
}
