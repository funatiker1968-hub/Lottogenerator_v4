import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

Future<void> main() async {
  print('🧪 DATENBANK-IMPORT-TEST (NUR TXT)');
  print('==================================');

  // 1. Datenbank öffnen
  final path = join(await getDatabasesPath(), 'lotto.db');
  print('📁 Öffne Datenbank: $path');
  
  final db = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      print('✅ Tabelle wird erstellt...');
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
    },
  );

  // 2. Prüfen, ob Daten vorhanden sind
  final count = await db.rawQuery('SELECT COUNT(*) FROM ziehungen');
  final vorhanden = count.first.values.first as int;
  print('📊 Aktuelle Ziehungen in DB: $vorhanden');

  if (vorhanden == 0) {
    print('🔄 Datenbank ist leer. Starte Import...');
    
    // 3. Lotto 6aus49 aus TXT importieren (Format: DD.MM.YYYY | n n n n n n | SZ)
    try {
      print('📥 Lade lotto_1955_2025.txt...');
      final lottoTxt = await rootBundle.loadString('assets/data/lotto_1955_2025.txt');
      final lines = lottoTxt.trim().split('\n');
      print('   Gefunden: ${lines.length} Zeilen');
      
      int importiert = 0;
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(' | ');
        if (parts.length == 3) {
          await db.insert('ziehungen', {
            'spieltyp': '6aus49',
            'datum': parts[0].trim(), // DD.MM.YYYY
            'zahlen': json.encode(parts[1].trim().split(' ').map(int.parse).toList()),
            'superzahl': int.parse(parts[2].trim()),
          });
          importiert++;
          if (importiert % 500 == 0) print('   ... $importiert importiert');
        }
      }
      print('✅ Lotto 6aus49 Import: $importiert Ziehungen.');
    } catch (e) {
      print('❌ Lotto-TXT-Import fehlgeschlagen: $e');
    }

    // 4. Eurojackpot aus TXT importieren
    try {
      print('📥 Lade eurojackpot_2012_2025.txt...');
      final euroTxt = await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');
      final lines = euroTxt.trim().split('\n');
      print('   Gefunden: ${lines.length} Zeilen');
      
      int importiert = 0;
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(' | ');
        if (parts.length == 3) {
          await db.insert('ziehungen', {
            'spieltyp': 'eurojackpot',
            'datum': parts[0].trim(),
            'zahlen': json.encode(parts[1].trim().split(' ').map(int.parse).toList()),
            'superzahl': int.parse(parts[2].trim()),
          });
          importiert++;
        }
      }
      print('✅ Eurojackpot Import: $importiert Ziehungen.');
    } catch (e) {
      print('❌ Eurojackpot-Import fehlgeschlagen: $e');
    }

    // 5. Endgültige Zählung
    final endCount = await db.rawQuery('SELECT COUNT(*) FROM ziehungen');
    final gesamt = endCount.first.values.first as int;
    print('🎉 IMPORT ABSCHLUSS: $gesamt Ziehungen in Datenbank.');
  } else {
    print('ℹ️  Datenbank bereits befüllt.');
  }

  // 6. Aufschlüsselung nach Spieltyp
  final breakdown = await db.rawQuery('''
    SELECT spieltyp, COUNT(*) as count FROM ziehungen GROUP BY spieltyp
  ''');
  for (final row in breakdown) {
    print('   ${row['spieltyp']}: ${row['count']} Ziehungen');
  }

  await db.close();
  print('==================================');
  print('✅ TEST BEENDET.');
}
