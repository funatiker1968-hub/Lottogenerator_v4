import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lotto_data.dart';

class ErweiterteLottoDatenbank {
  static const String _dbName = 'lotto_daten.db';
  static const String _tableZiehungen = 'lotto_ziehungen';

  static Future<Database> _getDatabase() async {
    final pfad = await getDatabasesPath();
    final datenbankPfad = join(pfad, _dbName);

    final db = await openDatabase(
      datenbankPfad,
      version: 1,
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableZiehungen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datum TEXT NOT NULL,
        zahl1 INTEGER NOT NULL,
        zahl2 INTEGER NOT NULL,
        zahl3 INTEGER NOT NULL,
        zahl4 INTEGER NOT NULL,
        zahl5 INTEGER NOT NULL,
        zahl6 INTEGER NOT NULL,
        superzahl INTEGER NOT NULL,
        spieltyp TEXT NOT NULL,
        UNIQUE(datum, spieltyp)
      )
    ''');

    return db;
  }

  static Future<List<LottoZiehung>> holeLetzteZiehungen({
    required String spieltyp,
    int limit = 2,
  }) async {
    final db = await _getDatabase();
    final daten = await db.query(
      _tableZiehungen,
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
      limit: limit,
    );

    final ziehungen = <LottoZiehung>[];
    for (var eintrag in daten) {
      final datumString = eintrag['datum'] as String;
      final datum = DateTime.parse(datumString);
      final zahlen = <int>[
        eintrag['zahl1'] as int,
        eintrag['zahl2'] as int,
        eintrag['zahl3'] as int,
        eintrag['zahl4'] as int,
        eintrag['zahl5'] as int,
        eintrag['zahl6'] as int,
      ];
      ziehungen.add(LottoZiehung(
        datum: datum,
        zahlen: zahlen,
        superzahl: eintrag['superzahl'] as int,
        spieltyp: eintrag['spieltyp'] as String,
      ));
    }
    return ziehungen;
  }

  static Future<int> fuegeZiehungHinzu(LottoZiehung ziehung) async {
    final db = await _getDatabase();
    final datumIso = DateTime(
      ziehung.datum.year,
      ziehung.datum.month,
      ziehung.datum.day,
    ).toIso8601String().split('T').first;

    final zahlen = ziehung.zahlen;
    if (zahlen.length < 6) return 0;

    final data = <String, Object?>{
      'datum': datumIso,
      'zahl1': zahlen[0],
      'zahl2': zahlen[1],
      'zahl3': zahlen[2],
      'zahl4': zahlen[3],
      'zahl5': zahlen[4],
      'zahl6': zahlen[5],
      'superzahl': ziehung.superzahl,
      'spieltyp': ziehung.spieltyp,
    };

    try {
      await db.insert(
        _tableZiehungen,
        data,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return 1;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> fuegeZiehungenHinzu(List<LottoZiehung> ziehungen) async {
    int count = 0;
    for (final z in ziehungen) {
      count += await fuegeZiehungHinzu(z);
    }
    return count;
  }

  // --- Meta-Funktionen ---

  static Future<bool> hasAnyDraws() async {
    final db = await _getDatabase();
    final countResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_tableZiehungen');
    final cnt = Sqflite.firstIntValue(countResult) ?? 0;
    return cnt > 0;
  }

  static Future<DateTime?> getLastStoredDrawDate() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('SELECT datum FROM $_tableZiehungen ORDER BY datum DESC LIMIT 1');
    if (result.isEmpty) return null;
    final row = result.first;
    final dateStr = row['datum'] as String?;
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }
}
