import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class LottoDatabase {
  LottoDatabase._();
  static final LottoDatabase instance = LottoDatabase._();

  static Database? _db;

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
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ziehungen (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            spieltyp TEXT NOT NULL,
            datum TEXT NOT NULL,
            zahlen TEXT NOT NULL,
            superzahl INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> importLotto() async {
    final db = await database;
    await _importFromTxt(
      db,
      asset: 'assets/data/lotto_1955_2025.txt',
      spieltyp: '6aus49',
    );
  }

  Future<void> importEurojackpot() async {
    final db = await database;
    await _importFromTxt(
      db,
      asset: 'assets/data/eurojackpot_2012_2025.txt',
      spieltyp: 'eurojackpot',
    );
  }

  Future<void> _importFromTxt(
    Database db, {
    required String asset,
    required String spieltyp,
  }) async {
    final content = await rootBundle.loadString(asset);
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(' | ');
      if (parts.length != 3) continue;

      await db.insert('ziehungen', {
        'spieltyp': spieltyp,
        'datum': parts[0].trim(),
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

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
