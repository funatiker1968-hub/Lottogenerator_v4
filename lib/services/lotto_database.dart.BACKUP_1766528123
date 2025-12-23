import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import '../models/lotto_data.dart';

class LottoDatabase {
  // ============================================================
  // SINGLETON IMPLEMENTATION
  // ============================================================
  LottoDatabase._();
  static final LottoDatabase instance = LottoDatabase._();
  
  static Database? _db;

  // ============================================================
  // DATABASE INITIALIZATION
  // ============================================================
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'lottodaten.db');
    print('[DB] 📍 Pfad: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print('[DB] 🏗️  Erstelle Tabelle ziehungen...');
        await db.execute('''
          CREATE TABLE ziehungen (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            spieltyp TEXT NOT NULL,
            datum TEXT NOT NULL,
            zahlen TEXT NOT NULL,
            superzahl INTEGER
          )
        ''');
        print('[DB] ✅ Tabelle erstellt.');
        await _importAllFromTxt(db);
      },
      onOpen: (db) async {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ziehungen')
        ) ?? 0;
        print('[DB] 📊 Datenbank geöffnet. Enthält $count Einträge.');

        if (count == 0) {
          print('[DB] ⚠️  Datenbank ist LEER. Starte Import...');
          await _importAllFromTxt(db);
          final newCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM ziehungen')
          ) ?? 0;
          print('[DB] 📈 Nach Import: $newCount Einträge.');
        } else {
          print('[DB] ✅ Datenbank bereits gefüllt.');
        }
      },
    );
  }

  // ============================================================
  // TXT FILE IMPORT (ASSETS)
  // ============================================================
  Future<void> _importAllFromTxt(Database db) async {
    print('[DB] 🚀 STARTE IMPORT AUS TXT-DATEIEN');

    // 1. Lotto 6aus49 (Format: dd.mm.yyyy | z1 z2 z3 z4 z5 z6 | sz)
    try {
      print('[DB] 📥 Lese Lotto 6aus49 Daten...');
      final content = await rootBundle.loadString('assets/data/lotto_1955_2025.txt');
      final lines = content.split('\n');
      int imported = 0;

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        if (parts.length != 3) continue;

        final datum = parts[0].trim(); // dd.mm.yyyy
        final zahlen = parts[1].trim();
        final superzahl = parts[2].trim();

        await db.insert('ziehungen', {
          'spieltyp': 'lotto_6aus49',
          'datum': datum,
          'zahlen': zahlen,
          'superzahl': int.tryParse(superzahl) ?? 0,
        });

        imported++;
        if (imported % 1000 == 0) {
          print('[DB] ... $imported Lotto-Zeilen importiert');
        }
      }
      print('[DB] ✅ Lotto 6aus49: $imported Ziehungen importiert');
    } catch (e) {
      print('[DB] ❌ Lotto-Importfehler: $e');
    }

    // 2. Eurojackpot (Format: yyyy-mm-dd | z1 z2 z3 z4 z5 | e1 e2)
    try {
      print('[DB] 📥 Lese Eurojackpot Daten...');
      final content = await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');
      final lines = content.split('\n');
      int imported = 0;

      for (final line in lines) {
        if (line.trim().isEmpty || line.startsWith('#')) continue;
        final parts = line.split('|');
        if (parts.length != 3) continue;

        final datum = parts[0].trim(); // yyyy-mm-dd
        final zahlen = parts[1].trim();
        final eurozahlen = parts[2].trim();
        final alleZahlen = '$zahlen $eurozahlen';

        await db.insert('ziehungen', {
          'spieltyp': 'eurojackpot',
          'datum': datum,
          'zahlen': alleZahlen,
          'superzahl': 0,
        });

        imported++;
        if (imported % 100 == 0) {
          print('[DB] ... $imported EJ-Zeilen importiert');
        }
      }
      print('[DB] ✅ Eurojackpot: $imported Ziehungen importiert');
    } catch (e) {
      print('[DB] ❌ Eurojackpot-Importfehler: $e');
    }

    print('[DB] 🎉 IMPORT ABGESCHLOSSEN');
  }

  // ============================================================
  // DATABASE OPERATIONS
  // ============================================================
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      print('[DB] 🔒 Datenbank geschlossen');
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

  Future<List<LottoZiehung>> holeAlleZiehungen(String spieltyp) async {
    final db = await database;
    final rows = await db.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum ASC',
    );
    return rows.map(LottoZiehung.fromMap).toList();
  }

  // ============================================================
  // MANUAL IMPORT: LOTTO 6AUS49
  // ============================================================
  Future<Map<String, int>> importLotto6aus49Manually(String text) async {
    print("[DB] 📥 Starte manuellen Lotto 6aus49-Import");
    print("[DB] Textlänge: ${text.length} Zeichen");
    final lines = text.split("\n");
    print("[DB] Gefundene Zeilen: ${lines.length}");

    final db = await database;
    int imported = 0;
    int skipped = 0;
    int errors = 0;

    await db.transaction((txn) async {
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        print("[DB] 🔍 Verarbeite: $trimmed");

        try {
          final parsed = _parseLotto6aus49CompactLine(trimmed);
          if (parsed.isEmpty) {
            print("[DB] ❌ Parse fehlgeschlagen");
            errors++;
            continue;
          }

          final date = parsed["date"]!;
          final numbers = parsed["numbers"]!;
          final superzahl = int.tryParse(parsed["superzahl"] ?? "0") ?? 0;

          // Prüfe auf Duplikat
          final existing = await txn.rawQuery(
            "SELECT id FROM ziehungen WHERE spieltyp = ? AND datum = ?",
            ["lotto_6aus49", date]
          );

          if (existing.isNotEmpty) {
            print("[DB] ⏭️  Übersprungen (Datum bereits vorhanden: $date)");
            skipped++;
            continue;
          }

          await txn.insert("ziehungen", {
            "spieltyp": "lotto_6aus49",
            "datum": date,
            "zahlen": numbers,
            "superzahl": superzahl
          });

          imported++;
          print("[DB] ✅ Importiert: $date - $numbers (SZ: $superzahl)");

        } catch (e) {
          print("[DB] ❌ Fehler: $e");
          errors++;
        }
      }
    });

    print("[DB] ========================================");
    print("[DB] 📊 LOTTO IMPORT ABGESCHLOSSEN:");
    print("[DB] ✅ Importiert: $imported");
    print("[DB] ⏭️  Übersprungen: $skipped");
    print("[DB] ❌ Fehler: $errors");
    print("[DB] ========================================");

    return {
      "imported": imported,
      "skipped": skipped,
      "errors": errors
    };
  }

  Map<String, dynamic> _parseLotto6aus49CompactLine(String line) {
    try {
      // Format: ZNtt.mm.yyyyWWZZZZZZSZ (WW=Wochentag, SZ=Superzahl)
      // 1. Ersten Punkt finden
      final firstDot = line.indexOf(".");
      if (firstDot < 2) return {};

      // 2. Datumsteil extrahieren
      final beforeDot = line.substring(0, firstDot);
      final afterDot = line.substring(firstDot + 1);

      // 3. Tag extrahieren (letzte 2 Ziffern von beforeDot)
      if (beforeDot.length < 3) return {};
      final tag = beforeDot.substring(beforeDot.length - 2);
      final zn = beforeDot.substring(0, beforeDot.length - 2);

      // 4. Monat und Jahr
      final secondDot = afterDot.indexOf(".");
      if (secondDot != 2) return {};

      final month = afterDot.substring(0, secondDot);
      final afterSecondDot = afterDot.substring(secondDot + 1);

      if (afterSecondDot.length < 4) return {};
      final year = afterSecondDot.substring(0, 4);
      final remaining = afterSecondDot.substring(4);

      // 5. Zahlen parsen (Superzahl = letzte Ziffer)
      if (remaining.isEmpty) return {};

      final superzahlStr = remaining[remaining.length - 1];
      final superzahl = int.tryParse(superzahlStr) ?? 0;
      final numbersPart = remaining.substring(0, remaining.length - 1);

      final numbers = _parseLottoNumbersBackwards(numbersPart, superzahl);
      if (numbers.isEmpty) return {};

      // 6. Datum formatieren (dd-mm-yyyy)
      final dateStr = "$tag-$month-$year";

      return {
        "date": dateStr,
        "numbers": numbers.join(" "),
        "superzahl": superzahl.toString(),
        "zn": zn,
        "spieltyp": "lotto_6aus49"
      };
    } catch (e) {
      print("[DB] Parse-Fehler: $e");
      return {};
    }
  }

  List<int> _parseLottoNumbersBackwards(String numbersStr, int superzahl) {
    try {
      final digits = <int>[];
      for (int i = 0; i < numbersStr.length; i++) {
        final digit = int.tryParse(numbersStr[i]);
        if (digit != null) digits.add(digit);
      }

      if (digits.length < 6) return [];

      final totalDigits = digits.length;
      final twoDigitCount = totalDigits - 7; // Mathematische Formel
      final oneDigitCount = 6 - twoDigitCount;

      final numbers = <int>[];
      int pos = digits.length - 1;

      // Zahlen von hinten nach vorne parsen
      for (int i = 0; i < twoDigitCount; i++) {
        if (pos >= 1) {
          final twoDigit = digits[pos-1] * 10 + digits[pos];
          if (twoDigit >= 1 && twoDigit <= 49) {
            numbers.insert(0, twoDigit);
            pos -= 2;
          } else {
            return [];
          }
        } else {
          return [];
        }
      }

      for (int i = 0; i < oneDigitCount; i++) {
        if (pos >= 0) {
          final oneDigit = digits[pos];
          if (oneDigit >= 1 && oneDigit <= 9) {
            numbers.insert(0, oneDigit);
            pos -= 1;
          } else {
            return [];
          }
        } else {
          return [];
        }
      }

      // Validierung: aufsteigend sortiert und keine Duplikate
      if (numbers.length != 6) return [];
      for (int i = 1; i < numbers.length; i++) {
        if (numbers[i] <= numbers[i-1]) return [];
      }

      // Superzahl hinzufügen
      return numbers;
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // MANUAL IMPORT: EUROJACKPOT
  // ============================================================
  Future<Map<String, int>> importEurojackpotManually(String text) async {
    print("[DB] 📥 Starte manuellen Eurojackpot-Import");
    print("[DB] Textlänge: ${text.length} Zeichen");
    final lines = text.split("\n");
    print("[DB] Gefundene Zeilen: ${lines.length}");

    final db = await database;
    int imported = 0;
    int skipped = 0;
    int errors = 0;

    await db.transaction((txn) async {
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        print("[DB] 🔍 Verarbeite: $trimmed");

        try {
          final parsed = _parseEurojackpotCompactLine(trimmed);
          if (parsed.isEmpty) {
            print("[DB] ❌ Parse fehlgeschlagen");
            errors++;
            continue;
          }

          final date = parsed["date"]!;
          final numbers = parsed["numbers"]!;

          // Prüfe auf Duplikat
          final existing = await txn.rawQuery(
            "SELECT id FROM ziehungen WHERE spieltyp = ? AND datum = ?",
            ["eurojackpot", date]
          );

          if (existing.isNotEmpty) {
            print("[DB] ⏭️  Übersprungen (Datum bereits vorhanden: $date)");
            skipped++;
            continue;
          }

          await txn.insert("ziehungen", {
            "spieltyp": "eurojackpot",
            "datum": date,
            "zahlen": numbers,
            "superzahl": 0
          });

          imported++;
          print("[DB] ✅ Importiert: $date - $numbers");

        } catch (e) {
          print("[DB] ❌ Fehler: $e");
          errors++;
        }
      }
    });

    print("[DB] ========================================");
    print("[DB] 📊 EUROJACKPOT IMPORT ABGESCHLOSSEN:");
    print("[DB] ✅ Importiert: $imported");
    print("[DB] ⏭️  Übersprungen: $skipped");
    print("[DB] ❌ Fehler: $errors");
    print("[DB] ========================================");

    return {
      "imported": imported,
      "skipped": skipped,
      "errors": errors
    };
  }

  Map<String, String> _parseEurojackpotCompactLine(String line) {
    try {
      // Format: ZNtt.mm.yyyyZZZZZZ
      // 1. Ersten Punkt finden
      final firstDot = line.indexOf(".");
      if (firstDot < 2 || firstDot > 4) return {};

      // 2. ZN und Tag trennen
      final beforeFirstDot = line.substring(0, firstDot);
      if (beforeFirstDot.length < 3) return {};

      final tag = beforeFirstDot.substring(beforeFirstDot.length - 2);
      final zn = beforeFirstDot.substring(0, beforeFirstDot.length - 2);

      // 3. Monat und Jahr
      final afterFirstDot = line.substring(firstDot + 1);
      final secondDot = afterFirstDot.indexOf(".");
      if (secondDot != 2) return {};

      final month = afterFirstDot.substring(0, secondDot);
      final afterSecondDot = afterFirstDot.substring(secondDot + 1);

      if (afterSecondDot.length < 4) return {};
      final year = afterSecondDot.substring(0, 4);
      final numbersPart = afterSecondDot.substring(4);

      // 4. Validierung
      final znNum = int.tryParse(zn) ?? 0;
      final tagNum = int.tryParse(tag) ?? 0;
      final monthNum = int.tryParse(month) ?? 0;
      final yearNum = int.tryParse(year) ?? 0;

      if (znNum < 1 || znNum > 99) return {};
      if (tagNum < 1 || tagNum > 31) return {};
      if (monthNum < 1 || monthNum > 12) return {};
      if (yearNum < 2000 || yearNum > 2100) return {};

      // 5. Zahlen parsen (RÜCKWÄRTS)
      final numbers = _parseNumbersBackwards(numbersPart);
      if (numbers.isEmpty) return {};

      // 6. Datum formatieren (dd-mm-yyyy)
      final dateStr = "$tag-$month-$year";
      final numbersStr = numbers.join(" ");

      return {
        "date": dateStr,
        "numbers": numbersStr,
        "zn": zn,
        "spieltyp": "eurojackpot"
      };
    } catch (e) {
      print("[DB] Parse-Fehler: $e");
      return {};
    }
  }

  List<int> _parseNumbersBackwards(String numbersStr) {
    try {
      final digits = <int>[];
      for (int i = 0; i < numbersStr.length; i++) {
        final digit = int.tryParse(numbersStr[i]);
        if (digit != null) digits.add(digit);
      }

      if (digits.length < 7) return [];

      final euroNumbers = <int>[];
      final mainNumbers = <int>[];
      int pos = digits.length - 1;

      // 2 Eurozahlen (1-12) von hinten
      for (int i = 0; i < 2; i++) {
        bool found = false;

        // Prüfe 2-stellig (10, 11, 12)
        if (pos >= 1) {
          final twoDigit = digits[pos-1] * 10 + digits[pos];
          if (twoDigit >= 10 && twoDigit <= 12) {
            euroNumbers.insert(0, twoDigit);
            pos -= 2;
            found = true;
          }
        }

        // Prüfe 1-stellig (1-9)
        if (!found && pos >= 0) {
          final oneDigit = digits[pos];
          if (oneDigit >= 1 && oneDigit <= 9) {
            euroNumbers.insert(0, oneDigit);
            pos -= 1;
            found = true;
          }
        }

        if (!found) return [];
      }

      if (euroNumbers.length != 2) return [];

      // 5 Hauptzahlen (1-50) von hinten
      for (int i = 0; i < 5; i++) {
        bool found = false;

        // Prüfe 2-stellig (1-50)
        if (pos >= 1) {
          final twoDigit = digits[pos-1] * 10 + digits[pos];
          if (twoDigit >= 1 && twoDigit <= 50) {
            mainNumbers.insert(0, twoDigit);
            pos -= 2;
            found = true;
          }
        }

        // Prüfe 1-stellig (1-9)
        if (!found && pos >= 0) {
          final oneDigit = digits[pos];
          if (oneDigit >= 1 && oneDigit <= 9) {
            mainNumbers.insert(0, oneDigit);
            pos -= 1;
            found = true;
          }
        }

        if (!found) return [];
      }

      if (mainNumbers.length != 5) return [];

      // Validierung: Hauptzahlen müssen aufsteigend sein
      for (int i = 1; i < mainNumbers.length; i++) {
        if (mainNumbers[i] <= mainNumbers[i-1]) return [];
      }

      return [...mainNumbers, ...euroNumbers];
    } catch (e) {
      return [];
    }
  }
}
