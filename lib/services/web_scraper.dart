import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' show Element;

import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

/// Ergebnis-Klasse für Import-Operationen
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

/// Importer für Lotto 6aus49 (Archiv lottozahlenonline.de + Text)
class LottoOnlineScraper {
  static const String _basisUrl =
      'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php';

  // ======================================================================
  // A) ONLINE-IMPORT VON lottozahlenonline.de (jedes Jahr einzeln)
  // ======================================================================
  Future<ScraperResult> importVonLottozahlenOnline({
    required int startJahr,
    required int endJahr,
    String spieltyp = '6aus49',
  }) async {
    final result = ScraperResult();

    if (startJahr > endJahr) {
      result.errorMessage =
          "Startjahr ($startJahr) muss vor Endjahr ($endJahr) liegen.";
      return result;
    }

    if (startJahr < 1955 || endJahr > DateTime.now().year) {
      result.errorMessage =
          "Jahresbereiche müssen zwischen 1955 und ${DateTime.now().year} liegen.";
      return result;
    }

    int summe = 0;
    final fehler = <String>[];

    for (int jahr = startJahr; jahr <= endJahr; jahr++) {
      final r = await _importEinzelnesJahr(jahr, spieltyp);
      if (r.success) {
        summe += r.importedCount;
      } else {
        fehler.add("$jahr: ${r.errorMessage}");
      }

      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (summe > 0) {
      result.success = true;
      result.importedCount = summe;
      result.message = "Erfolgreich $summe Ziehungen importiert.";

      if (fehler.isNotEmpty) {
        result.message += "\n⚠️ Fehler: ${fehler.join("; ")}";
      }
    } else {
      result.errorMessage = "Import fehlgeschlagen.";
      if (fehler.isNotEmpty) {
        result.errorMessage += "\nFehler: ${fehler.join("; ")}";
      }
    }

    return result;
  }

  Future<ScraperResult> _importEinzelnesJahr(int jahr, String spieltyp) async {
    final result = ScraperResult();

    final url = "$_basisUrl?j=$jahr#lottozahlen-archiv";
    final uri = Uri.parse(url);

    try {
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode != 200) {
        result.errorMessage =
            "HTTP-Fehler ${response.statusCode} beim Laden von Jahr $jahr.";
        return result;
      }

      final ziehungen =
          _parseLottoArchivHtml(response.body, spieltyp);

      if (ziehungen.isEmpty) {
        result.errorMessage =
            "Keine Ziehungen im HTML gefunden – Seitenlayout evtl. geändert.";
        result.suggestion =
            "Öffne die Tabelle im Browser, kopiere sie und nutze den Textimport.";
        return result;
      }

      final gespeichert =
          await ErweiterteLottoDatenbank.fuegeZiehungenHinzu(ziehungen);

      result.success = true;
      result.importedCount = gespeichert;
      result.message =
          "Jahr $jahr: $gespeichert Ziehungen importiert.";

      return result;
    } catch (e) {
      result.errorMessage = "Fehler beim Import $jahr: $e";
      return result;
    }
  }

  // ======================================================================
  // B) HTML-PARSER – robuste Version ohne TableElement
  // ======================================================================
  List<LottoZiehung> _parseLottoArchivHtml(String html, String spieltyp) {
    final doc = parser.parse(html);

    // eine Tabelle finden, die Datum + Gewinnzahlen enthält
    Element? tabelle;

    for (final t in doc.querySelectorAll('table')) {
      final txt = t.text;
      if (txt.contains("Datum") && txt.contains("Gewinnzahlen")) {
        tabelle = t;
        break;
      }
    }

    if (tabelle == null) return [];

    final rows = tabelle.querySelectorAll('tr');

    final out = <LottoZiehung>[];

    for (final row in rows.skip(1)) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 10) continue;

      final dateStr = cells[1].text.trim();

      final zahlen = <int>[];
      for (int i = 3; i < 9; i++) {
        final n = int.tryParse(cells[i].text.trim());
        if (n == null) {
          zahlen.clear();
          break;
        }
        zahlen.add(n);
      }
      if (zahlen.length != 6) continue;

      final superZ = int.tryParse(cells[9].text.trim());
      if (superZ == null) continue;

      final datum = _parseDatum(dateStr);
      if (datum == null) continue;

      out.add(
        LottoZiehung(
          datum: datum,
          zahlen: zahlen,
          superzahl: superZ,
          spieltyp: spieltyp,
        ),
      );
    }

    return out;
  }

  // ======================================================================
  // C) TEXTIMPORT – universeller Parser
  // ======================================================================
  Future<ScraperResult> importFromText(String raw, String spieltyp) async {
    final result = ScraperResult();

    final lines = raw.split(RegExp(r'\r?\n'));
    final ziehungen = <LottoZiehung>[];

    for (final rawLine in lines) {
      final l = rawLine.trim();
      if (l.isEmpty) continue;

      final z = _parseTextZeile(l, spieltyp);
      if (z != null) ziehungen.add(z);
    }

    if (ziehungen.isEmpty) {
      result.errorMessage = "Keine gültigen Zeilen gefunden.";
      return result;
    }

    final gespeichert =
        await ErweiterteLottoDatenbank.fuegeZiehungenHinzu(ziehungen);

    result.success = gespeichert > 0;
    result.importedCount = gespeichert;
    result.message =
        "Erfolgreich $gespeichert Ziehungen importiert.";

    return result;
  }

  LottoZiehung? _parseTextZeile(String line, String spieltyp) {
    final dateMatch =
        RegExp(r'(\d{2}\.\d{2}\.\d{4})').firstMatch(line);
    if (dateMatch == null) return null;

    final dateStr = dateMatch.group(1)!;

    final after = line.substring(dateMatch.end);

    final dayMatch =
        RegExp(r'(Mo|Di|Mi|Do|Fr|Sa|So)').firstMatch(after);

    final int numbersStart =
        dayMatch != null ? (dateMatch.end + dayMatch.end!) : dateMatch.end;

    if (numbersStart >= line.length) return null;

    final tail = line.substring(numbersStart);

    final nums = RegExp(r'\d{1,2}').allMatches(tail).toList();

    if (nums.length < 7) return null;

    final main = <int>[];
    for (int i = 0; i < 6; i++) {
      final v = int.tryParse(nums[i].group(0)!);
      if (v == null) return null;
      main.add(v);
    }

    final sz = int.tryParse(nums[6].group(0)!);
    if (sz == null) return null;

    final datum = _parseDatum(dateStr);
    if (datum == null) return null;

    return LottoZiehung(
      datum: datum,
      zahlen: main,
      superzahl: sz,
      spieltyp: spieltyp,
    );
  }

  DateTime? _parseDatum(String d) {
    try {
      final tag = int.parse(d.substring(0, 2));
      final mon = int.parse(d.substring(3, 5));
      final jahr = int.parse(d.substring(6, 10));
      return DateTime(jahr, mon, tag);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _getHeaders() {
    return {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36",
      "Accept":
          "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    };
  }
}
