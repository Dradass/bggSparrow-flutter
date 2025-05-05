class CustomList {
  int id;
  final String name;
  String? value;

  CustomList({required this.id, required this.name, this.value});

  factory CustomList.fromJson(Map<String, dynamic> json) {
    return CustomList(name: json['name'], id: json['id'], value: json['value']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'value': value};
}
