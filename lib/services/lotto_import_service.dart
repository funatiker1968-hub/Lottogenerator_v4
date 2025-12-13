import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

class LottoImportService {

  // ===============================
  // IMPORT: 6aus49 aus JSON (Asset)
  // ===============================
  Future<void> import6aus49FromAsset({
    required void Function(String msg) status,
  }) async {

    status("Lade JSON aus assets/data/lotto_6aus49.json ...");

    final jsonStr =
        await rootBundle.loadString('assets/data/lotto_6aus49.json');
    final raw = jsonDecode(jsonStr) as List;

    // Erwartet: List<Map> mit keys: date, variable, value
    final Map<String, List<int>> zahlenProDatum = {};
    final Map<String, int> superzahlProDatum = {};

    for (final e in raw) {
      final m = e as Map<String, dynamic>;

      final date =
          (m['date'] ?? '').toString().trim(); // "03.01.2024"
      final variable =
          (m['variable'] ?? '').toString().trim(); // Lottozahl | Superzahl
      final value = m['value'];

      if (date.isEmpty) continue;

      final v =
          (value is int) ? value : int.tryParse(value.toString());
      if (v == null) continue;

      if (variable == 'Lottozahl') {
        zahlenProDatum.putIfAbsent(date, () => []).add(v);
      } else if (variable == 'Superzahl') {
        superzahlProDatum[date] = v;
      }
    }

    status("Gruppiert: ${zahlenProDatum.length} Ziehungs-Tage gefunden.");

    int neu = 0;
    int doppelt = 0;
    int fehler = 0;
    int done = 0;

    final dates = zahlenProDatum.keys.toList()
      ..sort((a, b) => _parseDate(a).compareTo(_parseDate(b)));

    for (final dateStr in dates) {
      done++;

      final zahlen =
          List<int>.from(zahlenProDatum[dateStr] ?? const []);
      final sz = superzahlProDatum[dateStr];

      if (zahlen.length != 6 || sz == null) {
        fehler++;
        if (fehler <= 10) {
          status(
              "⚠️ Übersprungen: $dateStr (zahlen=${zahlen.length}, SZ=${sz ?? 'null'})");
        }
        continue;
      }

      zahlen.sort();
      final date = _parseDate(dateStr);

      final z = LottoZiehung(
        datum: date,
        spieltyp: '6aus49',
        zahlen: zahlen,
        superzahl: sz,
      );

      final existiert =
          await ErweiterteLottoDatenbank.pruefeObSchonVorhanden(
              '6aus49', date);

      if (existiert) {
        doppelt++;
      } else {
        await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(z);
        neu++;
      }

      if (done % 200 == 0) {
        status(
            "Fortschritt: $done/${dates.length} | neu=$neu | doppelt=$doppelt | fehler=$fehler");
      }
    }

    status(
        "✔️ Import fertig: neu=$neu | doppelt=$doppelt | fehler=$fehler | tage=${dates.length}");
  }

  // =========================================
  // UI-WRAPPER (erwartet von Import-Screens)
  // =========================================
  Future<void> importBereich({
    required String bereich,
    required void Function(String msg) status,
  }) async {
    if (bereich == '6aus49') {
      await import6aus49FromAsset(status: status);
      return;
    }

    status("❌ Import-Bereich nicht unterstützt: $bereich");
  }

  // ===============================
  // HELFER
  // ===============================
  DateTime _parseDate(String dmy) {
    final p = dmy.split('.');
    final d = int.parse(p[0]);
    final m = int.parse(p[1]);
    final y = int.parse(p[2]);
    return DateTime(y, m, d);
  }
}

  Future<void> import6aus49FromCsvAsset({
    required String assetPath,
    required void Function(String msg) status,
  }) async {
    status("Lade CSV aus $assetPath ...");

    final csv = await rootBundle.loadString(assetPath);
    final lines = csv.split('\n');

    int neu = 0;
    int fehler = 0;

    for (final l in lines.skip(1)) {
      if (l.trim().isEmpty) continue;

      final p = l.split(';');
      if (p.length < 8) {
        fehler++;
        continue;
      }

      final date = _parseDate(p[0]);
      final zahlen = p.sublist(1, 7).map(int.parse).toList();
      final superzahl = int.parse(p[7]);

      final z = LottoZiehung(
        datum: date,
        spieltyp: '6aus49',
        zahlen: zahlen,
        superzahl: superzahl,
      );

      final exists = await ErweiterteLottoDatenbank
          .pruefeObSchonVorhanden('6aus49', date);

      if (!exists) {
        await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(z);
        neu++;
      }
    }

    status("CSV-Import fertig. Neu=$neu Fehler=$fehler");
  }

DateTime _parseDate(String dmy) {
  // Erwartet: DD.MM.YYYY
  final p = dmy.split('.');
  final d = int.parse(p[0]);
  final m = int.parse(p[1]);
  final y = int.parse(p[2]);
  return DateTime(y, m, d);
}
