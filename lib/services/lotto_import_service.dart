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

    final Map<String, List<int>> zahlenProDatum = {};
    final Map<String, int> superzahlProDatum = {};

    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      final date = (m['date'] ?? '').toString().trim();
      final variable = (m['variable'] ?? '').toString().trim();
      final value = m['value'];

      if (date.isEmpty) continue;

      final v = (value is int) ? value : int.tryParse(value.toString());
      if (v == null) continue;

      if (variable == 'Lottozahl') {
        zahlenProDatum.putIfAbsent(date, () => []).add(v);
      } else if (variable == 'Superzahl') {
        superzahlProDatum[date] = v;
      }
    }

    int neu = 0;
    int doppelt = 0;
    int fehler = 0;

    final dates = zahlenProDatum.keys.toList()
      ..sort((a, b) => _parseDate(a).compareTo(_parseDate(b)));

    for (final dateStr in dates) {
      final zahlen = List<int>.from(zahlenProDatum[dateStr] ?? const []);
      final sz = superzahlProDatum[dateStr];

      if (zahlen.length != 6 || sz == null) {
        fehler++;
        continue;
      }

      zahlen.sort();
      final date = _parseDate(dateStr);

      final ziehung = LottoZiehung(
        datum: date,
        spieltyp: '6aus49',
        zahlen: zahlen,
        superzahl: sz,
      );

      final exists = await ErweiterteLottoDatenbank
          .pruefeObSchonVorhanden('6aus49', date);

      if (!exists) {
        await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(ziehung);
        neu++;
      } else {
        doppelt++;
      }
    }

    status("✔️ Lotto-Import fertig: neu=$neu doppelt=$doppelt fehler=$fehler");
  }

  // =========================================
  // STUB: wird vom Import-Screen erwartet
  // =========================================
  Future<void> importRange({
    required DateTime start,
    required DateTime end,
    required void Function(String msg) status,
  }) async {
    status("Lotto-Import Bereich (Stub)");
  }

  // ===============================
  // HELFER
  // ===============================
  DateTime _parseDate(String dmy) {
    final p = dmy.split('.');
    return DateTime(
      int.parse(p[2]),
      int.parse(p[1]),
      int.parse(p[0]),
    );
  }
}

  // ===============================
  // MANUELLER BEREICHS-IMPORT (UI)
  // ===============================
  Future<void> importRange({
    required DateTime start,
    required DateTime end,
    required void Function(String msg) status,
  }) async {
    status("ℹ️ Lotto 6aus49 Bereichsimport: ${start.year}–${end.year}");
    status("ℹ️ (Logik folgt – Stub OK)");
  }
