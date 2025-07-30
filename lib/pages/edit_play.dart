import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/bgg_play_model.dart';
import '../models/game_thing.dart';
import '../widgets/log_page_widgets.dart';
import '../widgets/players_list.dart';
import '../widgets/common.dart';
import '../bggApi/bgg_api.dart';

class EditPage extends StatefulWidget {
  EditPage({required this.bggPlay, super.key});
  BggPlay bggPlay;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late final PlayDatePickerSimple playDatePickerSimple;
  late final LocationPickerSimple locationPickerSimple;
  late final CommentsSimple commentsSimple;
  late final DurationSliderSimple durationSliderSimple;
  late final PlayersPickerSimple playersPickerSimple;
  PlayersListWrapper playersListWrapper = PlayersListWrapper();

  @override
  void initState() {
    super.initState();
    playDatePickerSimple = PlayDatePickerSimple(date: widget.bggPlay.date);
    locationPickerSimple =
        LocationPickerSimple(location: widget.bggPlay.location ?? '');
    commentsSimple = CommentsSimple(comments: widget.bggPlay.comments ?? '');
    durationSliderSimple = DurationSliderSimple(
        durationCurrentValue: (widget.bggPlay.duration ?? 60).toDouble());
    playersPickerSimple =
        PlayersPickerSimple(playersListWrapper: playersListWrapper);
    playersListWrapper.sourceWinners = widget.bggPlay.winners;
    playersListWrapper.sourcePlayers = widget.bggPlay.players;
    playersListWrapper.updatePlayersFromCustomList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              FlexButton(playDatePickerSimple, 3),
              FlexButton(locationPickerSimple, 3),
              FlexButton(commentsSimple, 5),
              FlexButton(durationSliderSimple, 1),
              FlexButton(playersPickerSimple, 3),
              FlexButton(
                  ElevatedButton(
                    onPressed: () {
                      var formData = createFormData(
                          widget.bggPlay, playersListWrapper.players);
                      editBGGPlay(widget.bggPlay.id.toString(), formData);
                    },
                    child: Text("Save"),
                  ),
                  3),
              FlexButton(
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/navigation');
                    },
                    child: Text("Cancel"),
                  ),
                  3)
            ],
          ),
        ),
      ),
    );
  }
}
