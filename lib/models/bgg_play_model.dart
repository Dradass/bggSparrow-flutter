class BggPlay {
  final int id;
  final String date;
  final int? quantity;
  final String? location;
  final int gameId;
  final String? comments;
  final String? players;
  final String? winners;
  final int? duration;

  const BggPlay(
      {required this.id,
      required this.gameId,
      required this.date,
      this.quantity,
      this.comments,
      this.location,
      this.players,
      this.winners,
      this.duration});

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'gameId': gameId,
        'quantity': quantity,
        'location': location,
        'players': players,
        'winners': winners,
        'comments': comments,
        'duration': duration
      };

  factory BggPlay.fromJson(Map<String, dynamic> json) {
    return BggPlay(
        id: json['id'],
        gameId: json['gameId'],
        date: json['date'],
        quantity: json['quantity'],
        comments: json['comments'],
        location: json['location'],
        players: json['players'],
        winners: json['winners'],
        duration: json['duration']);
  }
}
