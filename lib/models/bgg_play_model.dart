class BggPlay {
  final int id;
  final String date;
  final int? quantity;
  final String? location;
  final int gameId;
  final String gameName;
  final String? comments;
  final String? players;
  final int? duration;
  final int? offline;
  final int? incomplete;
  final int? nowinstats;

  const BggPlay(
      {required this.id,
      required this.gameId,
      required this.gameName,
      required this.date,
      this.quantity,
      this.comments,
      this.location,
      this.players,
      this.duration,
      this.offline,
      this.incomplete,
      this.nowinstats});

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'gameId': gameId,
        'gameName': gameName,
        'quantity': quantity,
        'location': location,
        'players': players,
        'comments': comments,
        'duration': duration,
        'offline': offline,
        'incomplete': incomplete,
        'nowinstats': nowinstats
      };

  factory BggPlay.fromJson(Map<String, dynamic> json) {
    return BggPlay(
        id: json['id'],
        gameId: json['gameId'],
        gameName: json['gameName'],
        date: json['date'],
        quantity: json['quantity'],
        comments: json['comments'],
        location: json['location'],
        players: json['players'],
        duration: json['duration'],
        offline: json['offline'],
        incomplete: json['incomplete'],
        nowinstats: json['nowinstats']);
  }

  static bool areEqual(BggPlay firstPlay, BggPlay secondPlay) {
    if (firstPlay.comments == secondPlay.comments &&
        firstPlay.date == secondPlay.date &&
        firstPlay.duration == secondPlay.duration &&
        firstPlay.gameId == secondPlay.gameId &&
        firstPlay.gameName == secondPlay.gameName &&
        firstPlay.id == secondPlay.id &&
        firstPlay.incomplete == secondPlay.incomplete &&
        firstPlay.location == secondPlay.location &&
        firstPlay.nowinstats == secondPlay.nowinstats &&
        firstPlay.offline == secondPlay.offline &&
        firstPlay.players == secondPlay.players &&
        firstPlay.quantity == secondPlay.quantity) {
      return true;
    } else {
      return false;
    }
  }
}
