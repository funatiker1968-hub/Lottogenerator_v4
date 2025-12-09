/// Aktualisierte Version des Scrapers mit „safe insert“-Logik.
/// Holt Lotto-Ziehungen aus dem Online-Archiv, parst sie und speichert sie in der DB — überspringt Ziehungen, die bereits existieren.

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

class LottozahlenOnlineScraper {
  static const String _basisUrl =
    'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php';

  /// Importiert alle Ziehungen für die Jahre [startJahr] bis [endJahr] (inklusiv),
  /// schreibt nur neue Ziehungen (existierende werden übersprungen).
  static Future<ScraperResult> importVonLottozahlenOnline({
    required int startJahr,
    required int endJahr,
    String spieltyp = '6aus49',
  }) async {
    final result = ScraperResult();
    if (startJahr > endJahr) {
      result.success = false;
      result.errorMessage = 'Startjahr ($startJahr) muss vor dem Endjahr ($endJahr) liegen.';
      return result;
    }
    if (startJahr < 1955 || endJahr > DateTime.now().year) {
      result.success = false;
      result.errorMessage =
        'Jahre müssen zwischen 1955 und ${DateTime.now().year} liegen.';
      return result;
    }

    int gesamtImportiert = 0;
    final fehler = <String>[];

    for (int jahr = startJahr; jahr <= endJahr; jahr++) {
      final uri = Uri.parse('$_basisUrl?j=$jahr#lottozahlen-archiv');
      try {
        final response = await http.get(uri, headers: _getHeaders());
        if (response.statusCode != 200) {
          fehler.add('$jahr: HTTP-Fehler ${response.statusCode}');
          continue;
        }
        final ziehungen = _parseLottoArchivHtml(response.body, spieltyp);
        for (final ziehung in ziehungen) {
          final inserted = await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(ziehung);
          if (inserted > 0) gesamtImportiert += inserted;
        }
      } catch (e) {
        fehler.add('$jahr: Fehler beim Import – $e');
      }
      await Future.delayed(const Duration(milliseconds: 500)); // Server schonen
    }

    if (gesamtImportiert > 0) {
      result.success = true;
      result.importedCount = gesamtImportiert;
      result.message = 'Erfolgreich $gesamtImportiert neue Ziehungen importiert.';
      if (fehler.isNotEmpty) {
        result.message += '\n⚠️ Teilweise Fehler: ${fehler.join("; ")}';
      }
    } else {
      result.success = false;
      result.errorMessage = fehler.isNotEmpty
        ? 'Keine neuen Ziehungen oder alle vorhanden.\nFehler: ${fehler.join("; ")}'
        : 'Keine neuen Ziehungen gefunden.';
    }
    return result;
  }

  static Map<String, String> _getHeaders() => {
    'User-Agent': 'Mozilla/5.0',
    'Accept': 'text/html',
    'Accept-Language': 'de-DE,de;q=0.9',
    'Connection': 'keep-alive',
  };
}

/// Hilfsklasse für Ergebnis
class ScraperResult {
  bool success;
  int importedCount;
  String message;
  String errorMessage;
  String suggestion;

  ScraperResult({
    this.success = false,
    this.importedCount = 0,
    this.message = '',
    this.errorMessage = '',
    this.suggestion = '',
  });

  @override
  String toString() {
    if (success) {
      return '✅ $message';
    } else {
      return '❌ $errorMessage${suggestion.isNotEmpty ? "\n$suggestion" : ""}';
    }
  }
}

// Interne: HTML parsen
List<LottoZiehung> _parseLottoArchivHtml(String html, String spieltyp) {
  final doc = parser.parse(html);
  TableElement? zielTabelle;
  for (final t in doc.querySelectorAll('table')) {
    final text = t.text;
    if (text.contains('Datum') && text.contains('Gewinnzahlen')) {
      zielTabelle = t as TableElement;
      break;
    }
  }
  if (zielTabelle == null) return [];

  final rows = zielTabelle.querySelectorAll('tr');
  final ziehungen = <LottoZiehung>[];
  for (final row in rows.skip(1)) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 10) continue;
    final dateStr = cells[1].text.trim();
    final main = <int>[];
    for (int i = 3; i < 9; i++) {
      final n = int.tryParse(cells[i].text.trim());
      if (n == null) {
        main.clear();
        break;
      }
      main.add(n);
    }
    if (main.length != 6) continue;
    final superStr = cells[9].text.trim();
    final superzahl = int.tryParse(superStr);
    if (superzahl == null) continue;

    final datum = _parseDatum(dateStr);
    if (datum == null) continue;
    ziehungen.add(LottoZiehung(
      datum: datum,
      zahlen: main,
      superzahl: superzahl,
      spieltyp: spieltyp,
    ));
  }
  return ziehungen;
}

DateTime? _parseDatum(String dateStr) {
  if (dateStr.length != 10) return null;
  try {
    final tag = int.parse(dateStr.substring(0, 2));
    final monat = int.parse(dateStr.substring(3, 5));
    final jahr = int.parse(dateStr.substring(6));
    return DateTime(jahr, monat, tag);
  } catch (_) {
    return null;
  }
}
