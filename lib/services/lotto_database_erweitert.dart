import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lotto_data.dart';

class ErweiterteLottoDatenbank {
  static Database? _db;

  static Future<Database> _getDb() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lottodaten.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ziehungen (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            datum TEXT NOT NULL,
            spieltyp TEXT NOT NULL,
            zahlen TEXT NOT NULL,
            superzahl INTEGER NOT NULL
          );
        ''');
      },
    );

    return _db!;
  }

  static String _serializeZahlen(List<int> zahlen) =>
      zahlen.join(',');

  static List<int> _parseZahlen(String daten) =>
      daten.split(',').map(int.parse).toList();

  static Future<bool> pruefeObSchonVorhanden(
      String spieltyp, DateTime datum) async {
    final db = await _getDb();
    final result = await db.query(
      'ziehungen',
      where: 'spieltyp = ? AND datum = ?',
      whereArgs: [spieltyp, datum.toIso8601String()],
    );
    return result.isNotEmpty;
  }

  static Future<void> fuegeZiehungWennNeu(LottoZiehung z) async {
    final vorhanden =
        await pruefeObSchonVorhanden(z.spieltyp, z.datum);
    if (vorhanden) return;

    final db = await _getDb();
    await db.insert('ziehungen', {
      'datum': z.datum.toIso8601String(),
      'spieltyp': z.spieltyp,
      'zahlen': _serializeZahlen(z.zahlen),
      'superzahl': z.superzahl,
    });
  }

  static Future<List<LottoZiehung>> holeLetzteZiehungen({
    required String spieltyp,
    required int limit,
  }) async {
    final db = await _getDb();
    final data = await db.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
      limit: limit,
    );

    return data.map((row) {
      return LottoZiehung(
        datum: DateTime.parse(row['datum'] as String),
        spieltyp: row['spieltyp'] as String,
        zahlen: _parseZahlen(row['zahlen'] as String),
        superzahl: row['superzahl'] as int,
      );
    }).toList();
  }
}
