import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/game_thing.dart';

class GameThingSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async => await db.execute(
            "CREATE TABLE Games(id INTEGER PRIMARY KEY, name TEXT NOT NULL, image TEXT NOT NULL, thumbnail TEXT NOT NULL, thumbbin TEXT);"),
        version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE Games(id INTEGER PRIMARY KEY, name TEXT NOT NULL, image TEXT NOT NULL, thumbnail TEXT NOT NULL, thumbbin TEXT);");
  }

  static void dropTable() async {
    final db = await _getDB();
    await db.execute("DROP TABLE Games;");
  }

  static Future<int> addGame(GameThing gameThing) async {
    final name = gameThing.name;
    print("Adding game thing $name");
    final db = await _getDB();
    return await db.insert("Games", gameThing.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateGame(GameThing gameThing) async {
    final db = await _getDB();
    return await db.update("Games", gameThing.toJson(),
        where: 'id = ?',
        whereArgs: [gameThing.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deleteGame(GameThing gameThing) async {
    final db = await _getDB();
    return await db.delete("Games", where: 'id = ?', whereArgs: [gameThing.id]);
  }

  static Future<List<GameThing>?> getAllGames() async {
    final db = await _getDB();
    final List<Map<String, dynamic>> maps = await db.query("Games");

    if (maps.isEmpty) {
      return null;
    }

    return List.generate(
        maps.length, (index) => GameThing.fromJson(maps[index]));
  }
}
