import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lotto_data.dart';

class ErweiterteLottoDatenbank {
  // ------------------------------------------------------------
  //  Datenbank erstellen oder öffnen
  // ------------------------------------------------------------
  static Future<Database> _getDatabase() async {
    final pfad = await getDatabasesPath();
    final datenbankPfad = join(pfad, 'lotto_daten.db');

    return await openDatabase(
      datenbankPfad,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lotto_ziehungen (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            datum TEXT NOT NULL,
            zahl1 INTEGER NOT NULL,
            zahl2 INTEGER NOT NULL,
            zahl3 INTEGER NOT NULL,
            zahl4 INTEGER NOT NULL,
            zahl5 INTEGER NOT NULL,
            zahl6 INTEGER NOT NULL,
            superzahl INTEGER NOT NULL,
            spieltyp TEXT NOT NULL
          );
        ''');
      },
    );
  }

  // ------------------------------------------------------------
  //  Ziehung speichern
  // ------------------------------------------------------------
  static Future<void> fuegeZiehungHinzu(LottoZiehung ziehung) async {
    final db = await _getDatabase();

    await db.insert(
      'lotto_ziehungen',
      {
        'datum': ziehung.datum.toIso8601String(),
        'zahl1': ziehung.zahlen[0],
        'zahl2': ziehung.zahlen[1],
        'zahl3': ziehung.zahlen[2],
        'zahl4': ziehung.zahlen[3],
        'zahl5': ziehung.zahlen[4],
        'zahl6': ziehung.zahlen[5],
        'superzahl': ziehung.superzahl,
        'spieltyp': ziehung.spieltyp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------
  //  Letzte Ziehungen lesen (für HomeScreen)
  // ------------------------------------------------------------
  static Future<List<LottoZiehung>> holeLetzteZiehungen({
    required String spieltyp,
    int limit = 2,
  }) async {
    final db = await _getDatabase();

    final daten = await db.query(
      'lotto_ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
      limit: limit,
    );

    List<LottoZiehung> ziehungen = [];

    for (var eintrag in daten) {
      ziehungen.add(
        LottoZiehung(
          datum: DateTime.parse(eintrag['datum'] as String),
          zahlen: [
            eintrag['zahl1'] as int,
            eintrag['zahl2'] as int,
            eintrag['zahl3'] as int,
            eintrag['zahl4'] as int,
            eintrag['zahl5'] as int,
            eintrag['zahl6'] as int,
          ],
          superzahl: eintrag['superzahl'] as int,
          spieltyp: eintrag['spieltyp'] as String,
        ),
      );
    }

    return ziehungen;
  }
}
