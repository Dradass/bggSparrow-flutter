import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/system_parameters.dart';

class SystemParameterSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {}, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE SystemParameters(id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT);");
  }

  static void dropTable() async {
    final db = await _getDB();
    await db.execute("DROP TABLE SystemParameters;");
  }

  static Future<int> addSystemParameter(SystemParameter systemParameter) async {
    final db = await _getDB();
    return await db.insert("SystemParameters", systemParameter.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateSystemParameter(
      SystemParameter systemParameter) async {
    final db = await _getDB();
    return await db.update("SystemParameters", systemParameter.toJson(),
        where: 'id = ?',
        whereArgs: [systemParameter.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deleteSystemParameter(
      SystemParameter systemParameter) async {
    final db = await _getDB();
    return await db.delete("SystemParameters",
        where: 'id = ?', whereArgs: [systemParameter.id]);
  }

  static Future<SystemParameter?> selectSystemParameterById(int id) async {
    final db = await _getDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM SystemParameters WHERE id=?", [id]);
    if (result.isEmpty) return null;
    return SystemParameter.fromJson(result.first);
  }

  static Future<int> getMaxID() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM SystemParameters');
    if (result.isEmpty) return 0;
    return result.length;
  }

  static Future<List<Map>> getAllSystemParameters() async {
    final db = await _getDB();
    List<Map> systemParameters = [];
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM SystemParameters');
    if (result.isEmpty) return systemParameters;
    for (var systemParameterResult in result) {
      var systemParameter = SystemParameter.fromJson(systemParameterResult);
      systemParameters.add({
        'name': systemParameter.name,
        'id': systemParameter.id,
        'value': systemParameter.value
      });
    }
    return systemParameters;
  }

  static Future<int> addOrEditParameter(
      int id, String paramName, String value) async {
    // Check "first time" system param
    var param = await SystemParameterSQL.selectSystemParameterById(id);
    if (param == null) {
      return await SystemParameterSQL.addSystemParameter(
          SystemParameter(id: id, name: paramName, value: value));
    } else {
      return await SystemParameterSQL.updateSystemParameter(
          SystemParameter(id: id, name: paramName, value: value));
    }
  }
}
