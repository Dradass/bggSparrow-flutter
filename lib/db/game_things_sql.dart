import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/game_thing.dart';
import 'dart:developer';

class GameThingSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    String path = join(await getDatabasesPath(), _dbName);

    return openDatabase(path, onCreate: _onCreate, version: _version);
  }

  static void _onCreate(Database db, int version) async {
    await db.execute(
        "CREATE TABLE IF NOT EXISTS Games(id INTEGER PRIMARY KEY, name TEXT NOT NULL, image TEXT NOT NULL, thumbnail TEXT NOT NULL, thumbbin TEXT, minPlayers INTEGER, maxPlayers INTEGER, owned INTEGER, yearpublished DATETIME);");
    await db.execute(
        "CREATE TABLE Players(id INTEGER PRIMARY KEY, name TEXT NOT NULL, userid INTEGER, username TEXT);");
    await db.execute(
        "CREATE TABLE Locations(id INTEGER PRIMARY KEY, name TEXT NOT NULL, isDefault INTEGER);");
    await db.execute(
        "CREATE TABLE Plays(id INTEGER PRIMARY KEY, date DATETIME NOT NULL, quantity INTEGER, location TEXT, gameId INTEGER NOT NULL, gameName TEXT NOT NULL, comments TEXT, players TEXT, winners TEXT, duration INTEGER, offline INTEGER);");
    await db.execute(
        "CREATE TABLE SystemParameters(id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT);");
    await db.execute(
        "CREATE TABLE GameLists(id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT);");
    await db.execute(
        "CREATE TABLE PlayerLists(id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT);");
    log('TABLES WERE CREATED');
  }

  static Future<void> createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE IF NOT EXISTS Games(id INTEGER PRIMARY KEY, name TEXT NOT NULL, image TEXT NOT NULL, thumbnail TEXT NOT NULL, thumbbin TEXT, minPlayers INTEGER, maxPlayers INTEGER, owned INTEGER, yearpublished DATETIME);");
  }

  static Future<void> initTables() async {
    await _getDB();
  }

  static void deleteDB() async {
    final path = join(await getDatabasesPath(), _dbName);

    await deleteDatabase(path);
  }

  static void dropTable() async {
    final db = await _getDB();
    await db.execute("DROP TABLE Games;");
  }

  static Future<int> addGame(GameThing gameThing) async {
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

  static Future<GameThing?> selectGameByID(int gameId) async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Games WHERE id=?', [gameId]);
    if (result.isEmpty) return null;
    return GameThing.fromJson(result.first);
  }

  static Future<List<GameThing>?> getAllGames() async {
    final db = await _getDB();
    final List<Map<String, dynamic>> maps = await db.query("Games");

    if (maps.isEmpty) {
      return null;
    }
    var games = (List.generate(
        maps.length, (index) => GameThing.fromJson(maps[index])));
    games.sort((a, b) => a.name.compareTo(b.name));
    return games;
  }
}
