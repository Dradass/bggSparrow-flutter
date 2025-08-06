// Structure of player:
// (0) username="" | (1) userid="0" | (2) name="Саша" | (3) startposition=""
//| (4) color="" | (5) score="42" | (6) new="0" | (7) rating="0" | (8) win="1"

class BggPlayPlayer {
  final String username;
  final String userid;
  final String name;
  final String startposition;
  final String color;
  final String score;
  final String isNew;
  final String rating;
  final String win;

  const BggPlayPlayer(
      {required this.username,
      required this.userid,
      required this.name,
      required this.startposition,
      required this.color,
      required this.score,
      required this.isNew,
      required this.rating,
      required this.win});

  String toString() {
    return "$username|$userid|$name|$startposition|$color|$score|$isNew|$rating|$win";
  }

  factory BggPlayPlayer.fromString(String sourceString) {
    var sourceList = sourceString.split('|');
    return BggPlayPlayer(
        username: sourceList[0],
        userid: sourceList[1],
        name: sourceList[2],
        startposition: sourceList[3],
        color: sourceList[4],
        score: sourceList[5],
        isNew: sourceList[6],
        rating: sourceList[7],
        win: sourceList[8]);
  }

  static BggPlayPlayer getPlayerByName(
      List<BggPlayPlayer> bggPlayPlayersList, String username, String name) {
    if (username != "") {
      return bggPlayPlayersList.where((x) => x.username == username).first;
    } else {
      return bggPlayPlayersList
          .where((x) => x.name == name && x.username == "")
          .first;
    }
  }
}
