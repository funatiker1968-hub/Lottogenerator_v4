import 'lotto_database.dart';
import '../models/lotto_data.dart';

class ErweiterteLottoDatenbank {
  static final LottoDatabase _db = LottoDatabase();

  // ------------------------------------------------------------
  // Prüfen ob Ziehung existiert
  // ------------------------------------------------------------
  static Future<bool> pruefeObSchonVorhanden(
    String spieltyp,
    DateTime datum,
  ) async {
    final database = await _db.database;
    final res = await database.rawQuery(
      'SELECT 1 FROM ziehungen WHERE spieltyp = ? AND datum = ? LIMIT 1',
      [spieltyp, datum.toIso8601String()],
    );
    return res.isNotEmpty;
  }

  // ------------------------------------------------------------
  // Ziehung speichern
  // ------------------------------------------------------------
  static Future<void> fuegeZiehungWennNeu(LottoZiehung z) async {
    final exists = await pruefeObSchonVorhanden(z.spieltyp, z.datum);
    if (exists) return;

    final database = await _db.database;
    await database.insert(
      'ziehungen',
      z.toMap(),
    );
  }

  // ------------------------------------------------------------
  // Alle Ziehungen eines Spieltyps (für Statistik)
  // ------------------------------------------------------------
  static Future<List<LottoZiehung>> holeAlleZiehungen(
    String spieltyp,
  ) async {
    final database = await _db.database;
    final rows = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum ASC',
    );

    return rows.map(LottoZiehung.fromMap).toList();
  }

  // ------------------------------------------------------------
  // Zähle Ziehungen eines Spieltyps
  // ------------------------------------------------------------
  static Future<int> zaehleZiehungen(String spieltyp) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = ?',
      [spieltyp],
    );
    return result.first['count'] as int;
  }
}
