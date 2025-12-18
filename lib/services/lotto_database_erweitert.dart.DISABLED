import 'lotto_database.dart';
import '../models/lotto_data.dart';

class ErweiterteLottoDatenbank {
  static final LottoDatabase _db = LottoDatabase();

  // ------------------------------------------------------------
  // Prüfen ob Ziehung existiert (POSitional – wichtig!)
  // ------------------------------------------------------------
  static Future<bool> pruefeObSchonVorhanden(
    String spieltyp,
    DateTime datum,
  ) async {
    final res = await _db.rawQuery(
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

    await _db.insert(
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
    final rows = await _db.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum ASC',
    );

    return rows.map(LottoZiehung.fromMap).toList();
  }

  // ------------------------------------------------------------
  // Anzahl Ziehungen
  // ------------------------------------------------------------
  static Future<int> anzahlZiehungen(String spieltyp) async {
    final res = await _db.rawQuery(
      'SELECT COUNT(*) as c FROM ziehungen WHERE spieltyp = ?',
      [spieltyp],
    );
    return res.first['c'] as int;
  }

  // ------------------------------------------------------------
  // Letztes Ziehungsdatum
  // ------------------------------------------------------------
  static Future<DateTime?> holeLetztesZiehungsDatum(
    String spieltyp,
  ) async {
    final res = await _db.rawQuery(
      'SELECT datum FROM ziehungen WHERE spieltyp = ? ORDER BY datum DESC LIMIT 1',
      [spieltyp],
    );

    if (res.isEmpty) return null;
    return DateTime.parse(res.first['datum'] as String);
  }
}
