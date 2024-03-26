class Location {
  int id;
  final String name;

  Location({required this.id, required this.name});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(name: json['name'], id: json['id']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
