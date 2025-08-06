import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/bgg_play_model.dart';
import '../widgets/log_page_widgets.dart';
import '../widgets/players_list.dart';
import '../widgets/common.dart';
import '../bggApi/bgg_api.dart';
import '../models/bgg_play_player.dart';
import 'package:flutter_application_1/db/plays_sql.dart';
import '../s.dart';

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
      child: SafeArea(
        child: Column(
          children: [
            FlexButton(playDatePickerSimple, 3),
            FlexButton(locationPickerSimple, 3),
            FlexButton(commentsSimple, 5),
            FlexButton(durationSliderSimple, 2),
            FlexButton(playersPickerSimple, 3),
            FlexButton(
                ElevatedButton(
                  onPressed: () async {
                    var playersInfo = createBggPlayersInfo(
                        widget.bggPlay, playersListWrapper.players);
                    var formData = createFormData(
                        widget.bggPlay,
                        playDatePickerSimple.date,
                        locationPickerSimple.location,
                        commentsSimple.comments,
                        durationSliderSimple.durationCurrentValue
                            .toInt()
                            .toString(),
                        playersInfo);
                    var errorMessage = await editBGGPlay(
                        widget.bggPlay.id.toString(), formData);
                    if (errorMessage != "") {
                      showSnackBar(context, errorMessage);
                    } else {
                      showSnackBar(context, S.of(context).playResultsWasSaved);
                      // Update the play in the database
                      var sourcePlayerInfo = widget.bggPlay.players;
                      var bggPlayPlayersList = sourcePlayerInfo
                          ?.split(';')
                          .map((e) => BggPlayPlayer.fromString(e))
                          .toList();

                      var play = BggPlay(
                          id: widget.bggPlay.id,
                          offline: 0,
                          gameId: widget.bggPlay.gameId,
                          incomplete: widget.bggPlay.incomplete,
                          nowinstats: widget.bggPlay.nowinstats,
                          gameName: widget.bggPlay.gameName,
                          date: playDatePickerSimple.date,
                          comments: Comments().commentsController.text,
                          location: locationPickerSimple.location,
                          players: playersListWrapper.players
                              .where((e) => e['isChecked'] == true)
                              .map((e) =>
                                  '${e['username']}|${e['userid']}|${e['name']}|${BggPlayPlayer.getPlayerByName(bggPlayPlayersList!, e['username'], e['name']).startposition}|${BggPlayPlayer.getPlayerByName(bggPlayPlayersList!, e['username'], e['name']).color}|${BggPlayPlayer.getPlayerByName(bggPlayPlayersList!, e['username'], e['name']).score}|${BggPlayPlayer.getPlayerByName(bggPlayPlayersList!, e['username'], e['name']).rating}|${BggPlayPlayer.getPlayerByName(bggPlayPlayersList!, e['username'], e['name']).isNew}|${e['win'] == true ? 1 : 0}')
                              .join(';'),
                          winners: playersListWrapper.players
                              .where((item) => item['win'] == true)
                              .map((item) => item['name'])
                              .join(';'),
                          duration:
                              durationSliderSimple.durationCurrentValue.toInt(),
                          quantity: 1);
                      await PlaysSQL.updatePlay(play);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).saveChanges),
                ),
                3),
            FlexButton(
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).cancel),
                ),
                3)
          ],
        ),
      ),
    );
  }
}
