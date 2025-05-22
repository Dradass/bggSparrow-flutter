import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/game_list_model.dart';

class GameListSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {}, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE GameLists(id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT);");
  }

  static void dropTable() async {
    final db = await _getDB();
    await db.execute("DROP TABLE GameLists;");
  }

  static Future<int> addCustomList(GameList customList) async {
    final db = await _getDB();
    return await db.insert("GameLists", customList.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> addCustomListByName(String name, String listValue) async {
    final db = await _getDB();
    final newId = (await GameListSQL.getMaxID()) + 1;
    GameList customList = GameList(id: newId, name: name, value: listValue);
    return await db.insert("GameLists", customList.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateCustomList(GameList customList) async {
    final db = await _getDB();
    return await db.update("GameLists", customList.toJson(),
        where: 'id = ?',
        whereArgs: [customList.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deleteCustomList(GameList customList) async {
    final db = await _getDB();
    return await db
        .delete("GameLists", where: 'id = ?', whereArgs: [customList.id]);
  }

  static Future<GameList?> selectCustomListById(int id) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM GameLists WHERE id=?", [id]);
    if (result.isEmpty) return null;
    return GameList.fromJson(result.first);
  }

  static Future<GameList?> selectLocationByName(String name) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM GameLists WHERE name=?", [name]);
    if (result.isEmpty) return null;
    return GameList.fromJson(result.first);
  }

  static Future<int> getMaxID() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM GameLists');
    if (result.isEmpty) return 0;
    return result.length;
  }

  static Future<List<Map<String, dynamic>>> getAllGameLists() async {
    final db = await _getDB();
    List<Map<String, dynamic>> gameLists = [];
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM GameLists');
    if (result.isEmpty) return gameLists;
    for (var customListResult in result) {
      var customList = GameList.fromJson(customListResult);
      gameLists.add({
        'name': customList.name,
        'id': customList.id,
        'value': customList.value
      });
    }
    return gameLists;
  }

  static Future<int> addOrEditCustomList(
      int id, String paramName, String value) async {
    var param = await GameListSQL.selectCustomListById(id);
    if (param == null) {
      return await GameListSQL.addCustomList(
          GameList(id: id, name: paramName, value: value));
    } else {
      return await GameListSQL.updateCustomList(
          GameList(id: id, name: paramName, value: value));
    }
  }
}
