import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

class EurojackpotImportService {
  EurojackpotImportService._();
  static final instance = EurojackpotImportService._();

  /// Importiert Eurojackpot aus CSV, **nur wenn DB leer für Eurojackpot**
  Future<void> importIfEmpty({
    void Function(String msg)? status,
  }) async {
    final bereits = await _hatBereitsDaten();
    if (bereits) {
      status?.call("Eurojackpot: bereits vorhanden – Import übersprungen.");
      return;
    }

    status?.call("Lade CSV aus assets/data/eurojackpot.csv ...");
    final csv = await rootBundle.loadString('assets/data/eurojackpot.csv');
    final lines = const LineSplitter().convert(csv);

    int neu = 0;
    int fehler = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith('#')) continue; // Kommentarzeilen

      // Format:
      // YYYY-MM-DD | n1 n2 n3 n4 n5 | e1 e2
      final parts = line.split('|').map((e) => e.trim()).toList();
      if (parts.length != 3) {
        fehler++;
        continue;
      }

      try {
        final date = _parseDate(parts[0]);

        final zahlen = parts[1]
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .map(int.parse)
            .toList();

        final euro = parts[2]
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .map(int.parse)
            .toList();

        if (zahlen.length != 5 || euro.length != 2) {
          fehler++;
          continue;
        }

        final z = LottoZiehung(
          datum: date,
          spieltyp: 'eurojackpot',
          zahlen: [...zahlen, ...euro], // gemeinsam speichern
          superzahl: 0, // nicht benutzt bei EJ
        );

        await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(z);
        neu++;
      } catch (_) {
        fehler++;
      }
    }

    status?.call("✔️ Eurojackpot-Import fertig: neu=$neu | fehler=$fehler");
  }

  Future<bool> _hatBereitsDaten() async {
    final list = await ErweiterteLottoDatenbank.holeLetzteZiehungen(
      spieltyp: 'eurojackpot',
      limit: 1,
    );
    return list.isNotEmpty;
  }

  DateTime _parseDate(String iso) {
    final p = iso.split('-');
    return DateTime(
      int.parse(p[0]),
      int.parse(p[1]),
      int.parse(p[2]),
    );
  }
}
