import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

class EurojackpotImportService {
  EurojackpotImportService._();
  static final instance = EurojackpotImportService._();

  Future<void> importIfEmpty({required void Function(String) status}) async {
    status("📥 Lade Eurojackpot-Daten aus TXT...");

    final txt = await rootBundle.loadString(
      'assets/data/eurojackpot_2012_2025.txt',
    );

    final lines = const LineSplitter().convert(txt);

    int neu = 0;
    int skip = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith('#')) continue;

      // Format:
      // YYYY-MM-DD | n n n n n | e e
      final parts = line.split('|');
      if (parts.length != 3) {
        skip++;
        continue;
      }

      final date = DateTime.parse(parts[0].trim());

      final zahlen = parts[1]
          .trim()
          .split(RegExp(r'\s+'))
          .map(int.parse)
          .toList();

      final euro = parts[2]
          .trim()
          .split(RegExp(r'\s+'))
          .map(int.parse)
          .toList();

      if (zahlen.length != 5 || euro.length != 2) {
        skip++;
        continue;
      }

      final ziehung = LottoZiehung(
        datum: date,
        spieltyp: 'eurojackpot',
        zahlen: [...zahlen, ...euro],
        superzahl: 0,
      );

      final exists =
          await ErweiterteLottoDatenbank.pruefeObSchonVorhanden(
        'eurojackpot',
        date,
      );

      if (!exists) {
        await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(ziehung);
        neu++;
      }
    }

    status("✅ Eurojackpot-Import fertig: neu=$neu | übersprungen=$skip");
  }
}
