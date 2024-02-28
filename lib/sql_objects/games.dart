class Game {
  final int id;
  final String name;
  final String image;
  final String thumb;

  const Game({
    required this.id,
    required this.name,
    required this.image,
    required this.thumb,
  });

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'thumb': thumb,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Game{id: $id, name: $name, : $image, thumb: $thumb}';
  }
}
