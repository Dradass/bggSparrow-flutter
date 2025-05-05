import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/custom_list_model.dart';

class CustomListSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {}, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE CustomLists(id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT);");
  }

  static void dropTable() async {
    final db = await _getDB();
    await db.execute("DROP TABLE CustomLists;");
  }

  static Future<int> addCustomList(CustomList customList) async {
    final db = await _getDB();
    return await db.insert("CustomLists", customList.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> addCustomListByName(String name, String listValue) async {
    final db = await _getDB();
    final newId = (await CustomListSQL.getMaxID()) + 1;
    CustomList customList = CustomList(id: newId, name: name, value: listValue);
    return await db.insert("CustomLists", customList.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateCustomList(CustomList customList) async {
    final db = await _getDB();
    return await db.update("CustomLists", customList.toJson(),
        where: 'id = ?',
        whereArgs: [customList.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deleteCustomList(CustomList customList) async {
    final db = await _getDB();
    return await db
        .delete("CustomLists", where: 'id = ?', whereArgs: [customList.id]);
  }

  static Future<CustomList?> selectCustomListById(int id) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM CustomLists WHERE id=?", [id]);
    if (result.isEmpty) return null;
    return CustomList.fromJson(result.first);
  }

  static Future<CustomList?> selectLocationByName(String name) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM CustomLists WHERE name=?", [name]);
    if (result.isEmpty) return null;
    return CustomList.fromJson(result.first);
  }

  static Future<int> getMaxID() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM CustomLists');
    if (result.isEmpty) return 0;
    return result.length;
  }

  static Future<List<Map<String, dynamic>>> getAllCustomLists() async {
    final db = await _getDB();
    List<Map<String, dynamic>> customLists = [];
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM CustomLists');
    if (result.isEmpty) return customLists;
    for (var customListResult in result) {
      var customList = CustomList.fromJson(customListResult);
      customLists.add({
        'name': customList.name,
        'id': customList.id,
        'value': customList.value
      });
    }
    return customLists;
  }

  static Future<int> addOrEditCustomList(
      int id, String paramName, String value) async {
    var param = await CustomListSQL.selectCustomListById(id);
    if (param == null) {
      return await CustomListSQL.addCustomList(
          CustomList(id: id, name: paramName, value: value));
    } else {
      return await CustomListSQL.updateCustomList(
          CustomList(id: id, name: paramName, value: value));
    }
  }
}
