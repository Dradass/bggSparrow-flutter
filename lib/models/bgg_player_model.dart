
// final objectId = int.parse(play.getAttribute('id').toString());
// final date = play.getAttribute('date').toString();
// final location = play.getAttribute('location').toString();
// final quantity = play.getAttribute('quantity').toString();
// final gameId = int.parse(play.getAttribute('objectid').toString());
//final players = userName, userId, name, win

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
