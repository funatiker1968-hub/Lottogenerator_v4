/// Auto-generated: Safe Import Helper für Lotto-Ziehungen
/// Überschreibt ggf. vorhandene Datei — mit exist-check vor Insert

import 'package:sqflite/sqflite.dart';
import 'lotto_database_erweitert.dart';
import '../models/lotto_data.dart';

class LottoImportSafe {
  /// Prüft, ob eine Ziehung mit dem gegebenen Datum + Spieltyp schon existiert.
  static Future<bool> existsZiehung(DateTime datum, String spieltyp) async {
    final db = await ErweiterteLottoDatenbank._getDatabase();
    final dateStr = datum.toIso8601String().split('T').first;
    final List<Map<String, Object?>> rec = await db.query(
      ErweiterteLottoDatenbank._tableZiehungen,
      where: 'datum = ? AND spieltyp = ?',
      whereArgs: [dateStr, spieltyp],
      limit: 1,
    );
    return rec.isNotEmpty;
  }

  /// Fügt eine Ziehung nur dann ein, wenn sie noch nicht existiert.
  /// Gibt zurück: 1 wenn neu eingefügt, 0 wenn übersprungen (bereits vorhanden)
  static Future<int> safeInsertZiehung(LottoZiehung ziehung) async {
    final exists = await existsZiehung(ziehung.datum, ziehung.spieltyp);
    if (exists) {
      return 0;
    }
    return await ErweiterteLottoDatenbank.fuegeZiehungHinzu([ziehung]);
  }

  /// Import-Routine: mehrere Ziehungen, prüft für jede, ob bereits vorhanden
  static Future<int> importZiehungenSafe(List<LottoZiehung> ziehungen) async {
    int countInserted = 0;
    for (final z in ziehungen) {
      final inserted = await safeInsertZiehung(z);
      countInserted += inserted;
    }
    return countInserted;
  }
}
