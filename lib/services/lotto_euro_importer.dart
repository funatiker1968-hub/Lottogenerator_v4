import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

/// Fortschrittsdaten für den Import, damit die UI 3 Balken anzeigen kann.
class ImportProgress {
  final double lottoProgress;    // 0.0 – 1.0
  final double euroProgress;     // 0.0 – 1.0
  final double totalProgress;    // 0.0 – 1.0
  final String phase;            // z.B. 'Lotto', 'Eurojackpot', 'Fertig'
  final String message;          // z.B. 'Importiere Jahr 2012…'

  ImportProgress({
    required this.lottoProgress,
    required this.euroProgress,
    required this.totalProgress,
    required this.phase,
    required this.message,
  });
}

/// Zentraler Importer für Lotto 6aus49 (lottozahlenonline.de)
/// und Eurojackpot (eurojackpot-zahlen.eu).
class LottoEuroImporter {
  final http.Client _client;

  LottoEuroImporter({http.Client? client}) : _client = client ?? http.Client();

  /// Vollimport: Lotto + Eurojackpot über Jahrbereiche.
  Future<void> importiereAlles({
    required int lottoStartJahr,
    required int lottoEndJahr,
    required int euroStartJahr,
    required int euroEndJahr,
    required void Function(ImportProgress) onProgress,
    required void Function(String) onLog,
  }) async {
    // Bereich normalisieren
    if (lottoEndJahr < lottoStartJahr) {
      final tmp = lottoStartJahr;
      lottoStartJahr = lottoEndJahr;
      lottoEndJahr = tmp;
    }
    if (euroEndJahr < euroStartJahr) {
      final tmp = euroStartJahr;
      euroStartJahr = euroEndJahr;
      euroEndJahr = tmp;
    }

    final lottoYears = lottoEndJahr >= lottoStartJahr
        ? (lottoEndJahr - lottoStartJahr + 1)
        : 0;
    final euroYears = euroEndJahr >= euroStartJahr
        ? (euroEndJahr - euroStartJahr + 1)
        : 0;

    final totalYears = (lottoYears + euroYears).clamp(1, 1000);
    int doneLotto = 0;
    int doneEuro = 0;

    // --- Lotto 6aus49 ---
    for (int year = lottoStartJahr; year <= lottoEndJahr; year++) {
      onLog('Lotto 6aus49 – lade Jahr $year …');
      try {
        final ziehungen = await _ladeLottoJahr(year, onLog: onLog);
        onLog('Lotto 6aus49 – gefunden: ${ziehungen.length} Ziehungen für $year');
        for (final z in ziehungen) {
          await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(z);
        }
        onLog('Lotto 6aus49 – gespeicherte Ziehungen für $year: ${ziehungen.length}');
      } catch (e) {
        onLog('⚠️ Lotto 6aus49 – Fehler in Jahr $year: $e');
      }

      doneLotto++;
      final lottoProgress =
          lottoYears == 0 ? 0.0 : doneLotto / lottoYears;
      final euroProgress =
          euroYears == 0 ? 0.0 : doneEuro / euroYears;
      final totalProgress =
          (doneLotto + doneEuro) / totalYears;

      onProgress(
        ImportProgress(
          lottoProgress: lottoProgress,
          euroProgress: euroProgress,
          totalProgress: totalProgress,
          phase: 'Lotto',
          message: 'Lotto: Jahr $year fertig',
        ),
      );
    }

    // --- Eurojackpot ---
    for (int year = euroStartJahr; year <= euroEndJahr; year++) {
      onLog('Eurojackpot – lade Jahr $year …');
      try {
        final ziehungen = await _ladeEuroJahr(year, onLog: onLog);
        onLog('Eurojackpot – gefunden: ${ziehungen.length} Ziehungen für $year');
        for (final z in ziehungen) {
          await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(z);
        }
        onLog('Eurojackpot – gespeicherte Ziehungen für $year: ${ziehungen.length}');
      } catch (e) {
        onLog('⚠️ Eurojackpot – Fehler in Jahr $year: $e');
      }

      doneEuro++;
      final lottoProgress =
          lottoYears == 0 ? 0.0 : doneLotto / lottoYears;
      final euroProgress =
          euroYears == 0 ? 0.0 : doneEuro / euroYears;
      final totalProgress =
          (doneLotto + doneEuro) / totalYears;

      onProgress(
        ImportProgress(
          lottoProgress: lottoProgress,
          euroProgress: euroProgress,
          totalProgress: totalProgress,
          phase: 'Eurojackpot',
          message: 'Eurojackpot: Jahr $year fertig',
        ),
      );
    }

    onLog('✅ Import abgeschlossen.');
    onProgress(
      ImportProgress(
        lottoProgress: 1.0,
        euroProgress: 1.0,
        totalProgress: 1.0,
        phase: 'Fertig',
        message: 'Alle Jahre importiert.',
      ),
    );
  }

  // =============================
  //   Lotto 6aus49 (lottozahlenonline.de)
  // =============================

  Future<List<LottoZiehung>> _ladeLottoJahr(
    int jahr, {
    required void Function(String) onLog,
  }) async {
    final url =
        'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php?j=$jahr';
    onLog('Lade Lotto-Archiv-Seite: $url');
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      onLog('⚠️ Lotto $jahr – HTTP ${response.statusCode}, breche ab.');
      return [];
    }

    final doc = html_parser.parse(response.body);
    final rows = doc.querySelectorAll('tr');
    final result = <LottoZiehung>[];

    final dateReg = RegExp(r'\d{2}\.\d{2}\.\d{4}');

    for (final row in rows) {
      final text = row.text.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
      if (!dateReg.hasMatch(text)) continue;
      if (!text.contains('.$jahr')) continue;

      final numbers = RegExp(r'\d+')
          .allMatches(text)
          .map((m) => int.tryParse(m.group(0) ?? '') ?? -1)
          .toList();

      // Erwartet:
      // [index, tag, monat, jahr, n1, n2, n3, n4, n5, n6, superzahl, (evtl. extra ...)]
      if (numbers.length < 11) continue;

      final tag = numbers[1];
      final monat = numbers[2];
      final yearParsed = numbers[3];
      if (yearParsed != jahr) continue;

      final zahlen = numbers.sublist(4, 10); // 6 Zahlen
      final superzahl = numbers[10];

      try {
        final datum = DateTime(yearParsed, monat, tag);
        result.add(
          LottoZiehung(
            datum: datum,
            spieltyp: '6aus49',
            zahlen: zahlen,
            superzahl: superzahl,
          ),
        );
      } catch (e) {
        onLog('⚠️ Lotto $jahr – konnte Zeile nicht parsen: "$text" ($e)');
      }
    }

    return result;
  }

  // =============================
  //   Eurojackpot (eurojackpot-zahlen.eu)
  // =============================

  Future<List<LottoZiehung>> _ladeEuroJahr(
    int jahr, {
    required void Function(String) onLog,
  }) async {
    final url =
        'https://www.eurojackpot-zahlen.eu/eurojackpot-zahlenarchiv.php?j=$jahr';
    onLog('Lade Eurojackpot-Archiv-Seite: $url');
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      onLog('⚠️ Eurojackpot $jahr – HTTP ${response.statusCode}, breche ab.');
      return [];
    }

    final doc = html_parser.parse(response.body);
    final rows = doc.querySelectorAll('tr');
    final result = <LottoZiehung>[];

    final dateReg = RegExp(r'\d{2}\.\d{2}\.\d{4}');

    for (final row in rows) {
      final text = row.text.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
      if (!dateReg.hasMatch(text)) continue;
      if (!text.contains('.$jahr')) continue;

      final numbers = RegExp(r'\d+')
          .allMatches(text)
          .map((m) => int.tryParse(m.group(0) ?? '') ?? -1)
          .toList();

      // Erwartet:
      // [index, tag, monat, jahr, 5x Hauptzahlen, 2x Eurozahlen, (evtl. extra ...)]
      if (numbers.length < 11) continue;

      final tag = numbers[1];
      final monat = numbers[2];
      final yearParsed = numbers[3];
      if (yearParsed != jahr) continue;

      // 5 Hauptzahlen
      final haupt = numbers.sublist(4, 9);
      // 2 Eurozahlen
      final euro1 = numbers[9];
      final euro2 = numbers[10];

      final alleZahlen = <int>[
        ...haupt,
        euro1,
        euro2,
      ];

      try {
        final datum = DateTime(yearParsed, monat, tag);
        result.add(
          LottoZiehung(
            datum: datum,
            spieltyp: 'Eurojackpot',
            zahlen: alleZahlen,
            superzahl: 0, // Eurojackpot hat keine Superzahl im deutschen Sinn
          ),
        );
      } catch (e) {
        onLog('⚠️ Eurojackpot $jahr – konnte Zeile nicht parsen: "$text" ($e)');
      }
    }

    return result;
  }
}
