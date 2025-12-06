import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lotto_data.dart';

class EinfacheLottoDatenbank {
  static Database? _database;
  
  static Future<Database> get datenbank async {
    if (_database != null) return _database!;
    _database = await _initialisiereDatenbank();
    return _database!;
  }
  
  static Future<Database> _initialisiereDatenbank() async {
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
            zahl1 INTEGER, zahl2 INTEGER, zahl3 INTEGER,
            zahl4 INTEGER, zahl5 INTEGER, zahl6 INTEGER,
            superzahl INTEGER,
            spieltyp TEXT DEFAULT '6aus49'
          )
        ''');
        print('✅ Datenbank wurde erstellt!');
      },
    );
  }
  
  static Future<void> fuegeZiehungHinzu(LottoZiehung ziehung) async {
    final db = await datenbank;
    
    await db.insert('lotto_ziehungen', {
      'datum': ziehung.datum.toIso8601String(),
      'zahl1': ziehung.zahlen[0],
      'zahl2': ziehung.zahlen[1],
      'zahl3': ziehung.zahlen[2],
      'zahl4': ziehung.zahlen[3],
      'zahl5': ziehung.zahlen[4],
      'zahl6': ziehung.zahlen[5],
      'superzahl': ziehung.superzahl,
      'spieltyp': ziehung.spieltyp,
    });
    
    print('✅ Ziehung hinzugefügt: ${ziehung.formatierterDatum}');
  }
  
  static Future<List<LottoZiehung>> holeAlleZiehungen() async {
    final db = await datenbank;
    final daten = await db.query('lotto_ziehungen', orderBy: 'datum DESC');
    
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
  
  static Future<void> loescheAlleDaten() async {
    final db = await datenbank;
    await db.delete('lotto_ziehungen');
    print('🗑️  Alle Daten gelöscht!');
  }
  
  static Future<void> schliesseDatenbank() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
