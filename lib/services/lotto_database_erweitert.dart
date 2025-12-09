import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lotto_data.dart';

class ErweiterteLottoDatenbank {
  static const String _table = "ziehungen";

  static Future<Database> _db() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'lotto_database.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE ziehungen("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "datum TEXT NOT NULL,"
          "zahlen TEXT NOT NULL,"
          "superzahl INTEGER NOT NULL,"
          "spieltyp TEXT NOT NULL,"
          "UNIQUE(datum, spieltyp)"
          ")"
        );
        await db.execute(
          "CREATE INDEX idx_spieltyp_datum ON ziehungen(spieltyp, datum DESC)"
        );
      },
    );
    return database;
  }

  static Future<List<LottoZiehung>> holeLetzteZiehungen({
    required String spieltyp,
    int limit = 10,
  }) async {
    final db = await _db();
    final result = await db.query(
      _table,
      where: "spieltyp = ?",
      whereArgs: [spieltyp],
      orderBy: "datum DESC",
      limit: limit,
    );

    return result.map((m) {
      return LottoZiehung(
        datum: DateTime.parse(m['datum'] as String),
        zahlen: (m['zahlen'] as String).split(',').map(int.parse).toList(),
        superzahl: m['superzahl'] as int,
        spieltyp: m['spieltyp'] as String,
      );
    }).toList();
  }

  static Future<void> fuegeZiehungWennNeu(LottoZiehung z) async {
    final db = await _db();
    final exist = await db.query(
      _table,
      where: "datum = ? AND spieltyp = ?",
      whereArgs: [z.datum.toIso8601String(), z.spieltyp],
      limit: 1,
    );
    if (exist.isNotEmpty) return;

    await db.insert(_table, {
      "datum": z.datum.toIso8601String(),
      "zahlen": z.zahlen.join(","),
      "superzahl": z.superzahl,
      "spieltyp": z.spieltyp,
    });
  }

  static Future<void> fuegeZiehungenHinzu(List<LottoZiehung> liste) async {
    final db = await _db();
    final batch = db.batch();
    
    for (final z in liste) {
      // Prüfen ob bereits vorhanden
      final exist = await db.query(
        _table,
        where: "datum = ? AND spieltyp = ?",
        whereArgs: [z.datum.toIso8601String(), z.spieltyp],
        limit: 1,
      );
      
      if (exist.isEmpty) {
        batch.insert(_table, {
          "datum": z.datum.toIso8601String(),
          "zahlen": z.zahlen.join(","),
          "superzahl": z.superzahl,
          "spieltyp": z.spieltyp,
        });
      }
    }
    
    await batch.commit(noResult: true);
  }

  static Future<void> close() async {
    final db = await _db();
    await db.close();
  }
}
