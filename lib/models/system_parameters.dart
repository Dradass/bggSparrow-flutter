class SystemParameter {
  int id;
  final String name;
  String? value;

  SystemParameter({required this.id, required this.name, this.value});

  factory SystemParameter.fromJson(Map<String, dynamic> json) {
    return SystemParameter(
        name: json['name'], id: json['id'], value: json['value']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'value': value};
}
