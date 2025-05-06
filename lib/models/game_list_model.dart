class GameList {
  int id;
  final String name;
  String? value;

  GameList({required this.id, required this.name, this.value});

  factory GameList.fromJson(Map<String, dynamic> json) {
    return GameList(name: json['name'], id: json['id'], value: json['value']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'value': value};
}
