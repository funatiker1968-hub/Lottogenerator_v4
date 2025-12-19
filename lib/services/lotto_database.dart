import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class LottoDatabase {
  static Database? _db;

  /// UNNAMED CONSTRUCTOR (für bestehenden Code)
  LottoDatabase();

  /// Singleton optional nutzbar
  static final LottoDatabase instance = LottoDatabase._internal();
  LottoDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'lotto.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ziehungen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datum TEXT NOT NULL,
        spieltyp TEXT NOT NULL,
        zahlen TEXT NOT NULL,
        superzahl INTEGER NOT NULL
      )
    ''');

    await _importiereLottoTxt(db);
    await _importiereEurojackpotTxt(db);
  }

  Future<void> _importiereLottoTxt(Database db) async {
    final content =
        await rootBundle.loadString('assets/data/lotto_1955_2025.txt');

    for (final line in content.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.length < 3) continue;

      await db.insert('ziehungen', {
        'datum': parts[0].trim(),
        'spieltyp': '6aus49',
        'zahlen': parts[1].trim(),
        'superzahl': int.tryParse(parts[2].trim()) ?? 0,
      });
    }
  }

  Future<void> _importiereEurojackpotTxt(Database db) async {
    final content =
        await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');

    for (final line in content.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.length < 3) continue;

      await db.insert('ziehungen', {
        'datum': parts[0].trim(),
        'spieltyp': 'Eurojackpot',
        'zahlen': parts[1].trim(),
        'superzahl': int.tryParse(parts[2].trim()) ?? 0,
      });
    }
  }

  Future<int> anzahlZiehungen(String spieltyp) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) FROM ziehungen WHERE spieltyp = ?',
      [spieltyp],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// FEHLTE → wird von Screens benutzt
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
