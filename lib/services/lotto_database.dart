import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LottoDatabase {
  static final LottoDatabase _instance = LottoDatabase._internal();
  factory LottoDatabase() => _instance;
  LottoDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lottodaten.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ziehungen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        spieltyp TEXT NOT NULL,
        datum TEXT NOT NULL,
        zahlen TEXT NOT NULL,
        superzahl INTEGER
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_spieltyp_datum 
      ON ziehungen(spieltyp, datum)
    ''');
  }

  // === IMPORT-METHODEN FÜR TXT-DATEIEN ===

  Future<void> importLotto6aus49Line(String line) async {
    final parsed = _parseLotto6aus49CompactLine(line);
    final db = await database;
    
    await db.insert('ziehungen', {
      'spieltyp': 'lotto_6aus49',
      'datum': parsed['datum'],
      'zahlen': parsed['zahlen'],
      'superzahl': parsed['superzahl'],
    });
  }

  Future<void> importEurojackpotLine(String line) async {
    final parsed = _parseEurojackpotCompactLine(line);
    final db = await database;
    
    await db.insert('ziehungen', {
      'spieltyp': 'eurojackpot',
      'datum': parsed['datum'],
      'zahlen': parsed['zahlen'],
      'superzahl': -1,
    });
  }

  // === MANUELLE IMPORT-METHODEN ===

  Future<Map<String, int>> importLotto6aus49Manually(String text) async {
    final lines = const LineSplitter().convert(text);
    int imported = 0;
    int errors = 0;
    
    final db = await database;
    await db.transaction((txn) async {
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        
        try {
          final parsed = _parseLotto6aus49CompactLine(trimmed);
          
          final existing = await txn.query(
            'ziehungen',
            where: 'spieltyp = ? AND datum = ?',
            whereArgs: ['lotto_6aus49', parsed['datum']],
          );
          
          if (existing.isEmpty) {
            await txn.insert('ziehungen', {
              'spieltyp': 'lotto_6aus49',
              'datum': parsed['datum'],
              'zahlen': parsed['zahlen'],
              'superzahl': parsed['superzahl'],
            });
            imported++;
          }
        } catch (e) {
          errors++;
          print('Fehler beim Parsen von "$trimmed": $e');
        }
      }
    });
    
    return {'imported': imported, 'errors': errors};
  }

  Future<Map<String, int>> importEurojackpotManually(String text) async {
    final lines = const LineSplitter().convert(text);
    int imported = 0;
    int errors = 0;
    
    final db = await database;
    await db.transaction((txn) async {
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        
        try {
          final parsed = _parseEurojackpotCompactLine(trimmed);
          
          final existing = await txn.query(
            'ziehungen',
            where: 'spieltyp = ? AND datum = ?',
            whereArgs: ['eurojackpot', parsed['datum']],
          );
          
          if (existing.isEmpty) {
            await txn.insert('ziehungen', {
              'spieltyp': 'eurojackpot',
              'datum': parsed['datum'],
              'zahlen': parsed['zahlen'],
              'superzahl': -1,
            });
            imported++;
          }
        } catch (e) {
          errors++;
          print('Fehler beim Parsen von "$trimmed": $e');
        }
      }
    });
    
    return {'imported': imported, 'errors': errors};
  }

  // === PARSER-METHODEN ===

  Map<String, dynamic> _parseLotto6aus49CompactLine(String line) {
    final parts = line.split('.');
    if (parts.length < 3) {
      throw FormatException('Ungültiges Format: $line');
    }

    final day = parts[0].length > 2 ? parts[0].substring(parts[0].length - 2) : parts[0];
    final month = parts[1];
    final yearWithRest = parts[2];

    final year = yearWithRest.substring(0, 4);
    final rest = yearWithRest.substring(4);

    final weekday = rest.substring(0, 2);
    final numbersWithSuper = rest.substring(2);

    final numbers = _parseLottoNumbersBackwards(numbersWithSuper);
    final superzahl = numbers.removeLast();

    final dateStr = '${day.padLeft(2, '0')}-${month.padLeft(2, '0')}-$year';
    final numbersStr = numbers.join(' ');

    return {
      'datum': dateStr,
      'zahlen': numbersStr,
      'superzahl': superzahl,
    };
  }

  List<int> _parseLottoNumbersBackwards(String numbersStrWithSuper) {
    final result = <int>[];
    final chars = numbersStrWithSuper.split('').reversed.toList();
    
    int index = 0;
    int lastNumber = 100;

    final totalDigits = chars.length;
    final twoDigitCount = totalDigits - 7;
    final oneDigitCount = 6 - twoDigitCount;

    for (int i = 0; i < twoDigitCount; i++) {
      final twoDigit = int.parse(chars[index + 1] + chars[index]);
      if (twoDigit >= lastNumber || twoDigit > 49 || twoDigit < 1) {
        throw FormatException('Ungültige Zahl oder Reihenfolge: $twoDigit');
      }
      result.add(twoDigit);
      lastNumber = twoDigit;
      index += 2;
    }

    for (int i = 0; i < oneDigitCount; i++) {
      final oneDigit = int.parse(chars[index]);
      if (oneDigit >= lastNumber || oneDigit > 49 || oneDigit < 1) {
        throw FormatException('Ungültige Zahl oder Reihenfolge: $oneDigit');
      }
      result.add(oneDigit);
      lastNumber = oneDigit;
      index += 1;
    }

    final superzahl = int.parse(chars[index]);
    result.add(superzahl);

    result.sort();
    result.add(superzahl);

    return result;
  }

  Map<String, String> _parseEurojackpotCompactLine(String line) {
    final parts = line.split('.');
    if (parts.length < 3) {
      throw FormatException('Ungültiges Format: $line');
    }

    final day = parts[0].length > 2 ? parts[0].substring(parts[0].length - 2) : parts[0];
    final month = parts[1];
    final yearWithRest = parts[2];

    final year = yearWithRest.substring(0, 4);
    final numbersStr = yearWithRest.substring(4);

    final numbers = _parseEurojackpotNumbersBackwards(numbersStr);

    final dateStr = '${day.padLeft(2, '0')}-${month.padLeft(2, '0')}-$year';
    final numbersStrFormatted = numbers.join(' ');

    return {
      'datum': dateStr,
      'zahlen': numbersStrFormatted,
    };
  }

  List<int> _parseEurojackpotNumbersBackwards(String numbersStr) {
    final result = <int>[];
    final chars = numbersStr.split('').reversed.toList();
    
    int index = 0;
    int lastNumber = 100;

    for (int i = 0; i < 2; i++) {
      final eurozahl = int.parse(chars[index + 1] + chars[index]);
      if (eurozahl >= lastNumber || eurozahl > 12 || eurozahl < 1) {
        throw FormatException('Ungültige Eurozahl: $eurozahl');
      }
      result.add(eurozahl);
      lastNumber = eurozahl;
      index += 2;
    }

    lastNumber = 100;
    for (int i = 0; i < 5; i++) {
      final hauptzahl = int.parse(chars[index + 1] + chars[index]);
      if (hauptzahl >= lastNumber || hauptzahl > 50 || hauptzahl < 1) {
        throw FormatException('Ungültige Hauptzahl: $hauptzahl');
      }
      result.add(hauptzahl);
      lastNumber = hauptzahl;
      index += 2;
    }

    result.sort();

    return result;
  }

  // === DATENBANK-ABFRAGEN ===

  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ziehungen');
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getDrawsByType(String spieltyp, {int limit = 100}) async {
    final db = await database;
    return await db.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
      limit: limit,
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('ziehungen');
  }
}
