import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class LottoDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
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
            superzahl INTEGER,
            UNIQUE(spieltyp, datum)
          )
        ''');
        print('✅ Datenbank-Tabelle erstellt.');
      },
      onOpen: (db) async {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ziehungen')
        );
        if (count == 0) {
          print('🔄 Datenbank ist leer. Starte automatischen Import...');
          await _importiereInitialeDaten(db);
        } else {
          print('ℹ️  Datenbank bereits befüllt ($count Datensätze).');
        }
      },
    );
  }

  Future<void> _importiereInitialeDaten(Database db) async {
    try {
      print('📥 Lade Lotto 6aus49 JSON...');
      final lottoJson = await rootBundle.loadString('assets/data/lotto_6aus49.json');
      final List<dynamic> lottoData = json.decode(lottoJson);
      print('📊 Importiere ${lottoData.length} Lotto-Ziehungen...');
      final batch = db.batch();
      for (var i = 0; i < lottoData.length; i++) {
        var item = lottoData[i];
        batch.insert('ziehungen', {
          'spieltyp': '6aus49',
          'datum': item['datum'],
          'zahlen': json.encode(item['zahlen']),
          'superzahl': item['superzahl'],
        });
        if ((i + 1) % 100 == 0) {
          print('   ... $i von ${lottoData.length}');
        }
      }
      await batch.commit(noResult: true);
      var lastLotto = lottoData.last;
      print('✅ Lotto 6aus49 Import fertig. Letzter Datensatz: ${lastLotto['datum']} ${lastLotto['zahlen']} SZ:${lastLotto['superzahl']}');

      print('📥 Lade Eurojackpot TXT...');
      final euroTxt = await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');
      final lines = euroTxt.trim().split('\n');
      print('📊 Importiere ${lines.length} Eurojackpot-Ziehungen...');
      final batch2 = db.batch();
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        final parts = line.split(' | ');
        if (parts.length == 3) {
          batch2.insert('ziehungen', {
            'spieltyp': 'eurojackpot',
            'datum': parts[0].trim(),
            'zahlen': json.encode(parts[1].trim().split(' ').map(int.parse).toList()),
            'superzahl': int.parse(parts[2].trim()),
          });
        }
        if ((i + 1) % 50 == 0) {
          print('   ... $i von ${lines.length}');
        }
      }
      await batch2.commit(noResult: true);
      if (lines.isNotEmpty) {
        var lastLine = lines.last;
        var lastParts = lastLine.split(' | ');
        print('✅ Eurojackpot Import fertig. Letzter Datensatz: $lastLine');
      }
      print('🎉 Automatischer Import aller Daten abgeschlossen.');
    } catch (e) {
      print('❌ KRITISCHER IMPORTFEHLER: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('🗃️  Datenbankverbindung geschlossen.');
    }
  }
}
