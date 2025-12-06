import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lotto_data.dart';

// Korrigierte Erweiterung
class ErweiterteLottoDatenbank {
  static Future<List<LottoZiehung>> holeLetzteZiehungen({
    required String spieltyp,
    int limit = 2,
  }) async {
    final Database db = await _getDatabase();
    
    final daten = await db.query(
      'lotto_ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
      limit: limit,
    );
    
    final ziehungen = <LottoZiehung>[];
    
    for (var eintrag in daten) {
      final ziehung = LottoZiehung(
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
      );
      ziehungen.add(ziehung);
    }
    
    return ziehungen;
  }
  
  static Future<Database> _getDatabase() async {
    final pfad = await getDatabasesPath();
    final datenbankPfad = join(pfad, 'lotto_daten.db');
    
    return await openDatabase(
      datenbankPfad,
      version: 1,
    );
  }
}
