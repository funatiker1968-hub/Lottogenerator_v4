// ============================================================================
// BLOCK 1: IMPORTS
// ============================================================================
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/lotto_data.dart';
import 'lotto_database.dart';

// ============================================================================
// BLOCK 2: SCRAPER-KLASSE – LottoOnlineScraper
// ============================================================================
class LottoOnlineScraper {
  // --------------------------------------------------------------------------
  // Import-Versuch von lottozahlenonline.de
  // Hinweis: Website nutzt JavaScript → kein Direktimport möglich
  // --------------------------------------------------------------------------
  Future<ScraperResult> importVonLottozahlenOnline({
    required int startJahr,
    required int endJahr,
    String spieltag = 'beide',
  }) async {
    final result = ScraperResult();
    result.success = false;
    result.errorMessage =
        "❌ Automatischer Import nicht möglich. Die Website nutzt JavaScript.\n"
        "Bitte Jahr manuell öffnen, Tabelle kopieren und im Textfeld einfügen.";

    return result;
  }

  // --------------------------------------------------------------------------
  // PRIVATE: Einzeljahr-Import – absichtlich deaktiviert (JavaScript-Seite)
  // --------------------------------------------------------------------------
  Future<ScraperResult> _importEinzelnesJahr(int jahr, String spieltag) async {
    final result = ScraperResult();
    result.success = false;
    result.errorMessage =
        "❌ JavaScript-Website → automatischer Import unmöglich.\n"
        "Bitte Kopieren/Einfügen verwenden.";
    return result;
  }

  // --------------------------------------------------------------------------
  // HTTP-Header (für spätere Erweiterungen bereits korrekt enthalten)
  // --------------------------------------------------------------------------
  Map<String, String> _getHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
      'Connection': 'keep-alive',
    };
  }

  // --------------------------------------------------------------------------
  // MANUELLER TEXTIMPORT – funktioniert zuverlässig
  // Wird in lotto_import_page.dart aufgerufen
  // --------------------------------------------------------------------------
  Future<ScraperResult> importFromText(
      String rawText, String spieltyp) async {
    final result = ScraperResult();

    try {
      final lines = rawText.split("\n");
      int counter = 0;

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        // Zahlen extrahieren: 1–49
        final matches = RegExp(r"\b\d{1,2}\b").allMatches(line);
        final numbers = matches
            .map((m) => int.tryParse(m.group(0)!) ?? -1)
            .where((n) => n > 0 && n <= 49)
            .toList();

        if (numbers.length >= 6) {
          counter++;

          final ziehung = LottoZiehung(
            datum: DateTime.now().subtract(Duration(days: counter * 7)),
            zahlen: numbers.sublist(0, 6),
            superzahl: 0,
            spieltyp: spieltyp,
          );

          await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
        }
      }

      result.success = true;
      result.importedCount = counter;
      result.message = "Erfolgreich $counter Ziehungen importiert.";
    } catch (e) {
      result.success = false;
      result.errorMessage = "Fehler: $e";
    }

    return result;
  }
}

// ============================================================================
// BLOCK 3: ScraperResult – Ergebnisobjekt
// ============================================================================
class ScraperResult {
  bool success = false;
  int importedCount = 0;
  String message = '';
  String errorMessage = '';
  String suggestion = '';

  @override
  String toString() {
    if (success) {
      return "✅ $message";
    } else {
      return "❌ $errorMessage";
    }
  }
}
