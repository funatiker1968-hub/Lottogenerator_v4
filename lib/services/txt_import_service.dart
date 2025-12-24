// TXT Import Service für das Format: "dd.mm.yyyy | z1 z2 z3 z4 z5 z6 | sz"
import 'package:sqflite/sqflite.dart';
import 'lotto_database.dart';

class TxtImportService {
  final LottoDatabase db = LottoDatabase();

  // Parser für TXT-Format
  Future<Map<String, dynamic>> parseTxtLine(String line) async {
    try {
      final parts = line.split('|');
      if (parts.length != 3) {
        throw FormatException('Ungültiges TXT-Format: $line');
      }

      final dateStr = parts[0].trim();
      final numbersStr = parts[1].trim();
      final superzahlStr = parts[2].trim();

      // Datum konvertieren dd.mm.yyyy → dd-mm-yyyy
      final dateParts = dateStr.split('.');
      if (dateParts.length != 3) {
        throw FormatException('Ungültiges Datum: $dateStr');
      }
      
      final day = dateParts[0].padLeft(2, '0');
      final month = dateParts[1].padLeft(2, '0');
      final year = dateParts[2];
      final dbDate = '$day-$month-$year';

      // Zahlen validieren und sortieren
      final numbers = numbersStr.split(' ').map((n) {
        final num = int.parse(n.trim());
        if (num < 1 || num > 49) {
          throw FormatException('Ungültige Lottozahl: $num');
        }
        return num;
      }).toList();

      if (numbers.length != 6) {
        throw FormatException('Nicht genau 6 Zahlen: $numbersStr');
      }
      numbers.sort();

      // Superzahl validieren mit historischer Korrektur
      int superzahl;
      try {
        superzahl = int.parse(superzahlStr);
        final date = DateTime(int.parse(year), int.parse(month), int.parse(day));
        final superzahlEinfuehrung = DateTime(1991, 12, 7);
        if (date.isBefore(superzahlEinfuehrung)) {
          superzahl = -1;
        }
      } catch (e) {
        superzahl = -1;
      }

      return {
        'datum': dbDate,
        'zahlen': numbers.join(' '),
        'superzahl': superzahl,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Import einer TXT-Zeile
  Future<void> importTxtLine(String line) async {
    try {
      final parsed = await parseTxtLine(line);
      final database = await db.database;
      
      await database.insert('ziehungen', {
        'spieltyp': 'lotto_6aus49',
        'datum': parsed['datum'],
        'zahlen': parsed['zahlen'],
        'superzahl': parsed['superzahl'],
      });
    } catch (e) {
      rethrow;
    }
  }
}
