import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

/// Importer für LOTTO 6aus49 von lottozahlenonline.de
/// Beispiel-Quelle:
/// https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php?j=2024#lottozahlen-archiv
class Lotto6Aus49Importer {
  static const String _baseUrl =
      'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php';

  /// Importiert alle Jahre im Bereich [startJahr]..[endJahr].
  /// onProgress(jahr, anzahl):
  ///   - anzahl >= 0  => so viele Ziehungen verarbeitet
  ///   - anzahl < 0   => Fehler bei diesem Jahr
  Future<void> importiereJahresBereich(
    int startJahr,
    int endJahr, {
    void Function(int jahr, int anzahl)? onProgress,
  }) async {
    int from = startJahr;
    int to = endJahr;
    if (from > to) {
      final tmp = from;
      from = to;
      to = tmp;
    }

    for (int jahr = from; jahr <= to; jahr++) {
      try {
        final count = await _importiereJahr(jahr);
        if (onProgress != null) {
          onProgress(jahr, count);
        }
      } catch (_) {
        if (onProgress != null) {
          onProgress(jahr, -1);
        }
      }
    }
  }

  /// Holt ein Jahr aus dem Archiv und schreibt Ziehungen in die DB.
  /// Rückgabe: Anzahl verarbeiteter Ziehungen (nicht unbedingt "neu",
  /// Duplikate werden in der DB selbst gefiltert).
  Future<int> _importiereJahr(int jahr) async {
    final ziehungen = await _ladeJahrVomWeb(jahr);
    int processed = 0;

    for (final z in ziehungen) {
      await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(z);
      processed++;
    }

    return processed;
  }

  /// Lädt ein Jahr vom Web und parst die Tabelle in LottoZiehung-Objekte.
  Future<List<LottoZiehung>> _ladeJahrVomWeb(int jahr) async {
    final uri = Uri.parse('$_baseUrl?j=$jahr#lottozahlen-archiv');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} beim Laden von Jahr $jahr');
    }

    final document = html_parser.parse(response.body);

    // Heuristik: Nimm eine Tabelle, in der "Datum" und "Gewinnzahlen" vorkommen.
    final tables = document.querySelectorAll('table');
    dom.Element? zielTabelle;

    for (final table in tables) {
      final text = table.text.toLowerCase();
      if (text.contains('datum') && text.contains('gewinnzahlen')) {
        zielTabelle = table;
        break;
      }
    }

    zielTabelle ??= tables.isNotEmpty ? tables.first : null;

    if (zielTabelle == null) {
      throw Exception('Keine geeignete Tabelle für Jahr $jahr gefunden');
    }

    final List<LottoZiehung> result = [];

    for (final row in zielTabelle.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;

      final texts = cells
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (texts.isEmpty) continue;

      final dateIndex = texts.indexWhere(_istDatum);
      if (dateIndex == -1) continue;

      final dateStr = texts[dateIndex];
      DateTime datum;
      try {
        datum = _parseDatum(dateStr);
      } catch (_) {
        continue;
      }

      // Nach dem Datum kommt der Wochentag (Mi/Sa/etc.), den ignorieren wir.
      // Danach erwarten wir mind. 7 Zahlen:
      // 6 Gewinnzahlen + 1 Superzahl.
      final List<int> zahlenUndSz = [];
      for (int i = dateIndex + 2; i < texts.length; i++) {
        final n = int.tryParse(texts[i]);
        if (n == null) continue;
        zahlenUndSz.add(n);
        if (zahlenUndSz.length == 7) break;
      }

      if (zahlenUndSz.length < 7) {
        // Zeile nicht komplett → überspringen
        continue;
      }

      final mainNumbers = zahlenUndSz.sublist(0, 6);
      final superzahl = zahlenUndSz[6];

      result.add(
        LottoZiehung(
          datum: datum,
          spieltyp: '6aus49',
          zahlen: mainNumbers,
          superzahl: superzahl,
        ),
      );
    }

    return result;
  }

  static bool _istDatum(String t) {
    return RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(t);
  }

  static DateTime _parseDatum(String s) {
    final parts = s.split('.');
    if (parts.length != 3) {
      throw FormatException('Ungültiges Datum: $s');
    }
    final tag = int.parse(parts[0]);
    final monat = int.parse(parts[1]);
    final jahr = int.parse(parts[2]);
    return DateTime(jahr, monat, tag);
  }
}
