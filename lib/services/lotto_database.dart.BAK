import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class LottoDatabase {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> getDatabase() async {
    return LottoDatabase().database;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'lotto.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ziehungen (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            spieltyp TEXT NOT NULL,
            datum TEXT NOT NULL,
            zahlen TEXT NOT NULL,
            superzahl INTEGER
          )
        ''');
        print('✅ Tabelle erstellt. Starte Import...');
        await _importAllFromTxt(db);
      },
      onOpen: (db) async {
        // KEINE Prüfung mehr - Import passiert nur bei Neuerstellung
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ziehungen')
        );
        print('📊 Datenbank hat $count Einträge.');
      },
    );
  }

  Future<void> _importAllFromTxt(Database db) async {
    // 1. Lotto 6aus49
    try {
      final content = await rootBundle.loadString('assets/data/lotto_1955_2025.txt');
      final lines = content.split('\n');
      print('📥 Importiere ${lines.length} Lotto-Zeilen...');
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(' | ');
        if (parts.length != 3) continue;
        
        await db.insert('ziehungen', {
          'spieltyp': '6aus49',
          'datum': parts[0].trim(),
          'zahlen': parts[1].trim(),
          'superzahl': int.tryParse(parts[2].trim()) ?? 0,
        });
      }
      print('✅ Lotto importiert.');
    } catch (e) {
      print('❌ Lotto-Importfehler: $e');
    }

    // 2. Eurojackpot
    try {
      final content = await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');
      final lines = content.split('\n');
      print('📥 Importiere ${lines.length} Eurojackpot-Zeilen...');
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(' | ');
        if (parts.length != 3) continue;
        
        await db.insert('ziehungen', {
          'spieltyp': 'eurojackpot',
          'datum': parts[0].trim(),
          'zahlen': parts[1].trim(),
          'superzahl': int.tryParse(parts[2].trim()) ?? 0,
        });
      }
      print('✅ Eurojackpot importiert.');
    } catch (e) {
      print('❌ Eurojackpot-Importfehler: $e');
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
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
}
