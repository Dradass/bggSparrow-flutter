import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bgg_location.dart';

class LocationSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    print('db creating');
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {}, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE Locations(id INTEGER PRIMARY KEY, name TEXT NOT NULL);");
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
        await db.rawQuery('SELECT * FROM Locations');
    if (result.isEmpty) return 0;
    return result.length;
    //return null;
  }

  static Future<List<Map>> getAllPlayers() async {
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
        'default': false,
        'isChecked': false
      });
    }
    return locations;
  }
}
