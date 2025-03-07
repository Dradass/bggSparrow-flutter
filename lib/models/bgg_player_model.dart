class Player {
  int id;
  final int? userid;
  final String name;
  final String? username;

  Player({required this.id, required this.name, this.userid, this.username});

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
