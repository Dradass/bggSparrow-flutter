import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bgg_player_model.dart';
import 'dart:developer';

class PlayersSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {}, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE Players(id INTEGER PRIMARY KEY, name TEXT NOT NULL, userid INTEGER, username TEXT);");
  }

  static void dropTable() async {
    final db = await _getDB();
    await db.execute("DROP TABLE Players;");
  }

  static Future<int> addPlayer(Player player) async {
    log("Adding player ${player.name}, id = ${player.id}, userid = ${player.userid}, username = ${player.username}");
    final db = await _getDB();
    return await db.insert("Players", player.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateGame(Player player) async {
    final db = await _getDB();
    return await db.update("Players", player.toJson(),
        where: 'id = ?',
        whereArgs: [player.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deleteGame(Player player) async {
    final db = await _getDB();
    return await db.delete("Players", where: 'id = ?', whereArgs: [player.id]);
  }

  static Future<Player?> selectPlayerByUserID(int userId) async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Players WHERE userid=?', [userId]);
    if (result.isEmpty) return null;
    var foundPlayer = Player.fromJson(result.first);
    return foundPlayer;
  }

  static Future<Player?> selectPlayerByName(String name) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result = await db
        .rawQuery("SELECT * FROM Players WHERE name=? AND userid=0", [name]);
    if (result.isEmpty) return null;
    return Player.fromJson(result.first);
  }

  static Future<Player?> selectPlayerById(int id) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM Players WHERE id=?", [id]);
    if (result.isEmpty) return null;
    return Player.fromJson(result.first);
  }

  static Future<int> getMaxID() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT MAX(ID) FROM Players');
    var maxId = result.first.values.first;
    if (result.isEmpty || maxId == null) return 0;
    return maxId;
  }

  static Future<List<Map>> getAllPlayers() async {
    final db = await _getDB();
    List<Map> players = [];
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Players');
    if (result.isEmpty) return players;
    for (var playerResult in result) {
      var player = Player.fromJson(playerResult);
      if (player.name.isEmpty) continue;
      players.add({
        'name': player.name,
        'id': player.id,
        'isChecked': false,
        'win': false,
        'excluded': false,
        'username': player.username,
        'userid': player.userid
      });
    }
    players
        .sort(((a, b) => a['name'].toString().compareTo(b['name'].toString())));
    return players;
  }
}
