import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/player_list_model.dart';

class PlayerListSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {}, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE PlayerLists(id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT);");
  }

  static void dropTable() async {
    final db = await _getDB();
    await db.execute("DROP TABLE PlayerLists;");
  }

  static Future<int> addCustomList(PlayersList playersList) async {
    final db = await _getDB();
    return await db.insert("PlayerLists", playersList.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> addCustomListByName(String name, String listValue) async {
    final db = await _getDB();
    final newId = (await PlayerListSQL.getMaxID()) + 1;
    PlayersList playersList =
        PlayersList(id: newId, name: name, value: listValue);
    return await db.insert("PlayerLists", playersList.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateCustomList(PlayersList playersList) async {
    final db = await _getDB();
    return await db.update("PlayerLists", playersList.toJson(),
        where: 'id = ?',
        whereArgs: [playersList.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deleteCustomList(PlayersList playersList) async {
    final db = await _getDB();
    return await db
        .delete("PlayerLists", where: 'id = ?', whereArgs: [playersList.id]);
  }

  static Future<PlayersList?> selectCustomListById(int id) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM PlayerLists WHERE id=?", [id]);
    if (result.isEmpty) return null;
    return PlayersList.fromJson(result.first);
  }

  static Future<PlayersList?> selectLocationByName(String name) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM PlayerLists WHERE name=?", [name]);
    if (result.isEmpty) return null;
    return PlayersList.fromJson(result.first);
  }

  static Future<int> getMaxID() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM PlayerLists');
    if (result.isEmpty) return 0;
    return result.length;
  }

  static Future<List<Map<String, dynamic>>> getAllPlayerLists() async {
    final db = await _getDB();
    List<Map<String, dynamic>> PlayerLists = [];
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM PlayerLists');
    if (result.isEmpty) return PlayerLists;
    for (var playersListResult in result) {
      var playersList = PlayersList.fromJson(playersListResult);
      PlayerLists.add({
        'name': playersList.name,
        'id': playersList.id,
        'value': playersList.value
      });
    }
    return PlayerLists;
  }

  static Future<int> addOrEditCustomList(
      int id, String paramName, String value) async {
    var param = await PlayerListSQL.selectCustomListById(id);
    if (param == null) {
      return await PlayerListSQL.addCustomList(
          PlayersList(id: id, name: paramName, value: value));
    } else {
      return await PlayerListSQL.updateCustomList(
          PlayersList(id: id, name: paramName, value: value));
    }
  }
}
