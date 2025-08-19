import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/bgg_play_player.dart';
import '../bggApi/bgg_api.dart';
import '../s.dart';
import '../db/players_sql.dart';
import '../models/bgg_player_model.dart';
import '../widgets/players_list.dart';
import '../widgets/common.dart';

class PlayersPicker extends StatefulWidget {
  static PlayersPicker? _singleton;

  factory PlayersPicker(PlayersListWrapper playersListWrapper) {
    _singleton ??= PlayersPicker._internal(playersListWrapper);
    return _singleton!;
  }

  PlayersPicker._internal(this.playersListWrapper);

  PlayersListWrapper playersListWrapper;

  @override
  State<PlayersPicker> createState() => _PlayersPickerState();
}

class _PlayersPickerState extends State<PlayersPicker> {
  final playerNameController = TextEditingController();
  String? _errorText;

  Future<String?> addBggPlayer(String userName, context) async {
    final playerNameInfo = await getBggPlayerName(userName);
    if (playerNameInfo.isNotEmpty) {
      final playerName = playerNameInfo['preparedName'];
      final userId = playerNameInfo['id'];
      var foundResult = await PlayersSQL.selectPlayerByUserID(userId);
      if (foundResult != null) {
        return S.of(context).playerIsAlreadyInFriendsList;
      } else {
        final maxId = await PlayersSQL.getMaxID();
        final newPlayer = Player(
            id: maxId + 1,
            name: playerName,
            username: userName,
            userid: userId);
        PlayersSQL.addPlayer(newPlayer);

        widget.playersListWrapper.players.add({
          'name': playerName,
          'id': maxId + 1,
          'isChecked': false,
          'win': false,
          'excluded': false,
        });
        _errorText = null;
      }
      return null;
    } else {
      return S.of(context).playerWithThisNicknameNotFound;
    }
  }

  Future<String?> addNotBggPlayer(String playerName, context) async {
    var foundResult = await PlayersSQL.selectPlayerByName(playerName);
    if (foundResult != null) {
      return S.of(context).playerIsAlreadyInFriendsList;
    }
    final maxId = await PlayersSQL.getMaxID();
    widget.playersListWrapper.players.add({
      'name': playerName,
      'id': maxId + 1,
      'isChecked': false,
      'win': false,
      'excluded': false,
    });
    final newPlayer = Player(id: maxId + 1, name: playerName, userid: 0);
    PlayersSQL.addPlayer(newPlayer);
    widget.playersListWrapper.players
        .sort(((a, b) => a['name'].toString().compareTo(b['name'].toString())));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    widget.playersListWrapper.updateCustomLists(context);
    return ElevatedButton.icon(
        onPressed: () async {
          if (widget.playersListWrapper.players.isEmpty) {
            widget.playersListWrapper.players = await getAllPlayers();
          }
          showDialog(
              context: context,
              builder: (buildContext) {
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                      //insetPadding: EdgeInsets.zero,
                      title: Column(children: [
                        ExpansionTile(
                            collapsedIconColor:
                                Theme.of(context).colorScheme.primary,
                            tilePadding: EdgeInsets.zero,
                            title: Text(S.of(context).managePlayers,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor)),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        _errorText = await addNotBggPlayer(
                                            playerNameController.text, context);
                                        setState(() {});
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                      ),
                                      child: buildScaledText(context,
                                          S.of(context).addPlayer, false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        _errorText = await addBggPlayer(
                                            playerNameController.text, context);
                                        if (_errorText == null) {
                                          playerNameController.text = '';
                                        }
                                        setState(() {});
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                      ),
                                      child: buildScaledText(context,
                                          S.of(context).addBggPlayer, false),
                                    ),
                                  ),
                                ],
                              ),
                              TextField(
                                  controller: playerNameController,
                                  decoration: InputDecoration(
                                      labelText: S.of(context).newPlayerName,
                                      errorText: _errorText,
                                      hintText: S
                                          .of(context)
                                          .enterFriendNameOrNickname)),
                              //Players list
                              Row(
                                children: [
                                  UpdateButton(
                                    playersListWrapper:
                                        widget.playersListWrapper,
                                    parentStateUpdate: () => setState(() {}),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3.0),
                                      child: ChooseListDropdown(
                                        playersListWrapper:
                                            widget.playersListWrapper,
                                        parentStateUpdate: () =>
                                            setState(() {}),
                                      ),
                                    ),
                                  ),
                                  DeleteButton(
                                    playersListWrapper:
                                        widget.playersListWrapper,
                                    parentStateUpdate: () => setState(() {}),
                                  ),
                                ],
                              ),
                              Row(children: [
                                CreateButton(
                                    playersListWrapper:
                                        widget.playersListWrapper,
                                    parentStateUpdate: () => setState(() {})),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.38,
                                    child: ListNameField(
                                        playersListWrapper:
                                            widget.playersListWrapper)),
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.1,
                                    child: ShowAllPlayersButton(
                                        playersListWrapper:
                                            widget.playersListWrapper,
                                        parentStateUpdate: () =>
                                            setState(() {})))
                              ])
                            ]),
                      ]),
                      content: SingleChildScrollView(
                          child: Column(
                              children: widget.playersListWrapper.players
                                  .map((player) {
                        return ListTileTheme(
                            horizontalTitleGap: 0,
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ChoiceChip(
                                      label: Text(
                                        S.of(context).winQuestion,
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                      selected: player['win'],
                                      onSelected: (bool? value) {
                                        setState(() {
                                          player['win'] = value;
                                          if (player['win'] == true) {
                                            player['isChecked'] = true;
                                          }
                                        });
                                      },
                                      shape: const RoundedRectangleBorder(
                                        side: BorderSide(color: Colors.black12),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Tooltip(
                                            message: player['name'],
                                            child: Text(player['name'],
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor))))
                                  ]),
                              value: player['isChecked'],
                              onChanged: (bool? value) {
                                setState(() {
                                  player['isChecked'] = value;
                                });
                                if (player['isChecked'] == false) {
                                  player['win'] = false;
                                }
                              },
                            ));
                      }).toList())));
                });
              });
        },
        style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: Text(S.of(context).selectPlayers),
        icon: const Icon(Icons.people));
  }
}

class PlayersPickerSimple extends StatefulWidget {
  PlayersPickerSimple({required this.playersListWrapper, super.key});
  PlayersListWrapper playersListWrapper;

  @override
  State<PlayersPickerSimple> createState() => _PlayersPickerSimpleState();
}

class _PlayersPickerSimpleState extends State<PlayersPickerSimple> {
  final playerNameController = TextEditingController();
  String? _errorText;

  Future<String?> addBggPlayer(String userName, context) async {
    final playerNameInfo = await getBggPlayerName(userName);
    if (playerNameInfo.isNotEmpty) {
      final playerName = playerNameInfo['preparedName'];
      final userId = playerNameInfo['id'];
      var foundResult = await PlayersSQL.selectPlayerByUserID(userId);
      if (foundResult != null) {
        return S.of(context).playerIsAlreadyInFriendsList;
      } else {
        final maxId = await PlayersSQL.getMaxID();
        final newPlayer = Player(
            id: maxId + 1,
            name: playerName,
            username: userName,
            userid: userId);
        PlayersSQL.addPlayer(newPlayer);

        widget.playersListWrapper.players.add({
          'name': playerName,
          'id': maxId + 1,
          'isChecked': false,
          'win': false,
          'excluded': false,
        });
        _errorText = null;
      }
      return null;
    } else {
      return S.of(context).playerWithThisNicknameNotFound;
    }
  }

  Future<String?> addNotBggPlayer(String playerName, context) async {
    var foundResult = await PlayersSQL.selectPlayerByName(playerName);
    if (foundResult != null) {
      return S.of(context).playerIsAlreadyInFriendsList;
    }
    final maxId = await PlayersSQL.getMaxID();
    widget.playersListWrapper.players.add({
      'name': playerName,
      'id': maxId + 1,
      'isChecked': false,
      'win': false,
      'excluded': false,
    });
    final newPlayer = Player(id: maxId + 1, name: playerName, userid: 0);
    PlayersSQL.addPlayer(newPlayer);
    widget.playersListWrapper.players
        .sort(((a, b) => a['name'].toString().compareTo(b['name'].toString())));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    widget.playersListWrapper.updateCustomLists(context);
    return ElevatedButton.icon(
        onPressed: () async {
          if (widget.playersListWrapper.players.isEmpty) {
            widget.playersListWrapper.players = await getAllPlayers();
          }

          // Fill Checked and Win statused
          if (widget.playersListWrapper.sourcePlayers != null) {
            for (var sourcePlayerString
                in widget.playersListWrapper.sourcePlayers!.split(";")) {
              var bggPlayer = BggPlayPlayer.fromString(sourcePlayerString);
              if (bggPlayer.userid == '0') {
                var foundUser = widget.playersListWrapper.players
                    .where((e) => e['name'] == bggPlayer.name)
                    .first;
                foundUser['isChecked'] = true;
                foundUser['win'] = bggPlayer.win == '1' ? true : false;
              } else {
                var foundUser = widget.playersListWrapper.players
                    .where((e) => e['userid'].toString() == bggPlayer.userid)
                    .first;
                foundUser['isChecked'] = true;
                foundUser['win'] = bggPlayer.win == '1' ? true : false;
              }
            }
          }
          showDialog(
              context: context,
              builder: (buildContext) {
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                      //insetPadding: EdgeInsets.zero,
                      title: Column(children: [
                        ExpansionTile(
                            collapsedIconColor:
                                Theme.of(context).colorScheme.primary,
                            tilePadding: EdgeInsets.zero,
                            title: Text(S.of(context).managePlayers,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor)),
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async => {
                                      _errorText = await addNotBggPlayer(
                                          playerNameController.text, context),
                                      setState(() {})
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary),
                                    ),
                                    child: Text(S.of(context).addPlayer),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async => {
                                      _errorText = await addBggPlayer(
                                          playerNameController.text, context),
                                      setState(() {})
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary),
                                    ),
                                    child: Text(S.of(context).addBggPlayer),
                                  ),
                                ],
                              ),
                              TextField(
                                  controller: playerNameController,
                                  decoration: InputDecoration(
                                      labelText: S.of(context).newPlayerName,
                                      errorText: _errorText,
                                      hintText: S
                                          .of(context)
                                          .enterFriendNameOrNickname)),
                              //Players list
                              Row(children: [
                                UpdateButton(
                                    playersListWrapper:
                                        widget.playersListWrapper,
                                    parentStateUpdate: () => setState(() {})),
                                ChooseListDropdown(
                                    playersListWrapper:
                                        widget.playersListWrapper,
                                    parentStateUpdate: () => setState(() {})),
                                DeleteButton(
                                    playersListWrapper:
                                        widget.playersListWrapper,
                                    parentStateUpdate: () => setState(() {}))
                              ]),
                              Row(children: [
                                CreateButton(
                                    playersListWrapper:
                                        widget.playersListWrapper,
                                    parentStateUpdate: () => setState(() {})),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.38,
                                    child: ListNameField(
                                        playersListWrapper:
                                            widget.playersListWrapper)),
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.1,
                                    child: ShowAllPlayersButton(
                                        playersListWrapper:
                                            widget.playersListWrapper,
                                        parentStateUpdate: () =>
                                            setState(() {})))
                              ])
                            ]),
                      ]),
                      content: SingleChildScrollView(
                          child: Column(
                              children: widget.playersListWrapper.players
                                  .map((player) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    S.of(context).winQuestion,
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor),
                                  ),
                                  selected: player['win'],
                                  onSelected: (bool? value) {
                                    setState(() {
                                      player['win'] = value;
                                    });
                                    if (player['win'] == true) {
                                      player['isChecked'] = true;
                                    }
                                  },
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.black12),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(player['name'],
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .primaryColor)))
                              ]),
                          value: player['isChecked'],
                          onChanged: (bool? value) {
                            setState(() {
                              player['isChecked'] = value;
                            });
                            if (player['isChecked'] == false) {
                              player['win'] = false;
                            }
                          },
                        );
                      }).toList())));
                });
              });
        },
        style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: Text(S.of(context).selectPlayers),
        icon: const Icon(Icons.people));
  }
}
