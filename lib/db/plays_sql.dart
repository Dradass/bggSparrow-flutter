import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bgg_play_model.dart';

class PlaysSQL {
  static const int _version = 1;
  static const String _dbName = "Notes.db";

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async {
      // await db.execute(
      //     "CREATE TABLE Players(id INTEGER PRIMARY KEY, name TEXT NOT NULL, userid INTEGER, username TEXT);");
    }, version: _version);
  }

  static void createTable() async {
    final db = await _getDB();
    await db.execute(
        "CREATE TABLE Plays(id INTEGER PRIMARY KEY, date DATETIME NOT NULL, quantity INTEGER, location TEXT, gameId INTEGER NOT NULL, comments TEXT, players TEXT, winners TEXT, duration INTEGER);");
  }

  static void dropTable() async {
    final db = await _getDB();
    print('drop table');
    await db.execute("DROP TABLE Plays;");
  }

  static Future<int> addPlay(BggPlay bggPlay) async {
    print("Adding play id = ${bggPlay.id}");
    final db = await _getDB();
    //if (player.username == null) player.username = '';
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
    //return await db.("Games", where: 'id = ?', whereArgs: [gameThing.id]);
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Plays WHERE id=?', [playId]);
    if (result.isEmpty) {
      return null;
    }
    var foundPlayer = BggPlay.fromJson(result.first);
    return foundPlayer;
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
              ? startDate.add(Duration(days: -1))
              : DateTime(2000)) &&
          DateTime.parse(play.date).isBefore(endDate != null
              ? endDate.add(Duration(days: 1))
              : DateTime(3000)))
        plays.add(BggPlay.fromJson({
          'id': play.id,
          'gameId': play.gameId,
          'date': play.date,
          'quantity': play.quantity,
          'comments': play.comments,
          'location': play.location,
          'players': play.players,
          'winners': play.winners,
          'duration': play.duration,
        }));
    }
    return plays;
  }
}
