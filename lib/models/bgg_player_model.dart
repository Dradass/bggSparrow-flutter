class Player {
  int id;
  final String? username;
  final int? userid;
  final String name;

  final String? startposition;
  final String? color;
  final String? score;
  final String? isNew;
  final String? rating;
  final String? win;

  Player(
      {required this.id,
      this.username,
      required this.userid,
      required this.name,
      this.startposition,
      this.color,
      this.score,
      this.isNew,
      this.rating,
      this.win});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
        name: json['name'],
        id: json['id'],
        userid: json['userid'],
        username: json['username']);
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'userid': userid, 'username': username};
}
