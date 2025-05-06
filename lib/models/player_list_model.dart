class PlayersList {
  int id;
  final String name;
  String? value;

  PlayersList({required this.id, required this.name, this.value});

  factory PlayersList.fromJson(Map<String, dynamic> json) {
    return PlayersList(
        name: json['name'], id: json['id'], value: json['value']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'value': value};
}
