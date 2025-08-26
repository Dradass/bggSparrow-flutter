import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bgg_play_model.dart';

class PlaysSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {}, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE Plays(id INTEGER PRIMARY KEY, date DATETIME NOT NULL, quantity INTEGER, location TEXT, gameId INTEGER NOT NULL, gameName TEXT NOT NULL, comments TEXT, players TEXT, duration INTEGER, offline INTEGER, incomplete INTEGER, nowinstats INTEGER);");
  }

  static void dropTable() async {
    final db = await _getDB();
    await db.execute("DROP TABLE Plays;");
  }

  static Future<void> clearTable() async {
    final db = await _getDB();
    await db.delete('Plays');
  }

  static Future<int> addPlay(BggPlay bggPlay) async {
    final db = await _getDB();
    return await db.insert("Plays", bggPlay.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updatePlay(BggPlay bggPlay) async {
    final db = await _getDB();
    return await db.update("Plays", bggPlay.toJson(),
        where: 'id = ?',
        whereArgs: [bggPlay.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> deletePlay(BggPlay bggPlay) async {
    final db = await _getDB();
    return await db.delete("Plays", where: 'id = ?', whereArgs: [bggPlay.id]);
  }

  static Future<BggPlay?> selectPlayByID(int playId) async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Plays WHERE id=?', [playId]);
    if (result.isEmpty) {
      return null;
    }
    var foundPlayer = BggPlay.fromJson(result.first);
    return foundPlayer;
  }

  static Future<BggPlay?> getMaxIdPlay() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT * FROM Plays WHERE id=(SELECT MAX(id) FROM Plays)',
    );
    if (result.isEmpty) {
      return null;
    }
    var foundPlayer = BggPlay.fromJson(result.first);
    return foundPlayer;
  }

  static Future<int?> getMinFreeOfflinePlayId() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('select MIN(id) - 1 from Plays;');
    if (result.isEmpty) {
      return null;
    }
    var minId = result.first.values.first;
    if (minId > 0) {
      minId = -1;
    }
    return minId;
  }

  static Future<List<BggPlay>> selectOfflineLoggedPlays() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Plays WHERE offline=1');
    if (result.isEmpty) {
      return [];
    }
    List<BggPlay> foundPlayers = [];
    for (var bggPlay in result) {
      foundPlayers.add(BggPlay.fromJson(bggPlay));
    }
    return foundPlayers;
  }

  static Future<int> getMaxID() async {
    final db = await _getDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Plays');
    if (result.isEmpty) return 0;
    return result.length;
  }

  static Future<List<BggPlay>> getAllPlays(
      DateTime? startDate, DateTime? endDate) async {
    final db = await _getDB();
    List<BggPlay> plays = [];
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Plays');
    if (result.isEmpty) return plays;
    for (var playerResult in result) {
      var play = BggPlay.fromJson(playerResult);
      if (DateTime.parse(play.date).isAfter(startDate != null
              ? startDate.add(const Duration(days: -1))
              : DateTime(2000)) &&
          DateTime.parse(play.date).isBefore(endDate != null
              ? endDate.add(const Duration(days: 1))
              : DateTime(3000))) {
        plays.add(BggPlay.fromJson({
          'id': play.id,
          'gameId': play.gameId,
          'gameName': play.gameName,
          'date': play.date,
          'quantity': play.quantity,
          'comments': play.comments,
          'location': play.location,
          'players': play.players,
          'duration': play.duration,
        }));
      }
    }
    return plays;
  }
}
