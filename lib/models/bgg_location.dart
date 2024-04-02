class Location {
  int id;
  final String name;
  int isDefault;

  Location({required this.id, required this.name, this.isDefault = 0});

  factory Location.fromJson(Map<String, dynamic> json) {
    //print("json = $json");
    return Location(
        name: json['name'], id: json['id'], isDefault: json['isDefault']);
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'isDefault': isDefault};
}
