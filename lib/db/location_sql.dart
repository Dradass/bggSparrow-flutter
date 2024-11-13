import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bgg_location.dart';

class LocationSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {}, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE Locations(id INTEGER PRIMARY KEY, name TEXT NOT NULL, isDefault INTEGER);");
  }

  static void dropTable() async {
    final db = await _getDB();
    print('drop table');
    await db.execute("DROP TABLE Locations;");
  }

  static Future<int> addLocation(Location location) async {
    print("Adding location ${location.name}, id = ${location.id}");
    final db = await _getDB();
    return await db.insert("Locations", location.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateLocation(Location location) async {
    final db = await _getDB();
    return await db.update("Locations", location.toJson(),
        where: 'id = ?',
        whereArgs: [location.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deleteLocation(Location location) async {
    final db = await _getDB();
    return await db
        .delete("Locations", where: 'id = ?', whereArgs: [location.id]);
  }

  static Future<Location?> selectLocationByName(String name) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM Locations WHERE name=?", [name]);
    if (result.isEmpty) return null;
    return Location.fromJson(result.first);
  }

  static Future<int> getMaxID() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT MAX(ID) FROM Locations');
    var maxId = result.first.values.first;
    if (result.isEmpty || maxId == null) return 0;
    return maxId;
  }

  static Future<List<Map>> getAllLocations() async {
    final db = await _getDB();
    List<Map> locations = [];
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Locations');
    if (result.isEmpty) return locations;
    for (var locationResult in result) {
      var location = Location.fromJson(locationResult);
      locations.add({
        'name': location.name,
        'id': location.id,
        'isDefault': location.isDefault
      });
    }
    return locations;
  }

  static Future<Location?> getDefaultLocation() async {
    final db = await _getDB();
    List<Map> locations = [];
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Locations WHERE isdefault=1');
    print(result);
    if (result.isEmpty) return null;
    for (var locationResult in result) {
      var location = Location.fromJson(locationResult);
      locations.add({
        'name': location.name,
        'id': location.id,
        'isDefault': location.isDefault
      });
    }
    return Location.fromJson(result.first);
  }

  static void updateDefaultLocation(Location location) async {
    var defaultLocation = await getDefaultLocation();
    print(defaultLocation);

    if (defaultLocation != null) {
      updateLocation(Location(
          id: defaultLocation.id, name: defaultLocation.name, isDefault: 0));
    }

    updateLocation(location);
    print("new def loca = ${location.name}, isdefault = ${location.isDefault}");
  }
}
