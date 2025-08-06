class BggPlay {
  final int id;
  final String date;
  final int? quantity;
  final String? location;
  final int gameId;
  final String gameName;
  final String? comments;
  final String? players;
  final String? winners;
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
      this.winners,
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
        'winners': winners,
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
        winners: json['winners'],
        duration: json['duration'],
        offline: json['offline'],
        incomplete: json['incomplete'],
        nowinstats: json['nowinstats']);
  }
}
