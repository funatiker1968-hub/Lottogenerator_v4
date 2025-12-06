import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/lotto_data.dart';
import 'lotto_database.dart';

class LottoOnlineScraper {
  // ====== HAUPTPUNKTION: Import für lottozahlenonline.de ======
  Future<ScraperResult> importVonLottozahlenOnline({
    required int startJahr,
    required int endJahr,
    String spieltag = 'beide',
  }) async {
    final result = ScraperResult();
    int gesamtImportiert = 0;
    List<String> fehler = [];

    print('🔄 Importiere Jahre $startJahr bis $endJahr von lottozahlenonline.de...');

    // 1. Prüfe Eingabe
    if (startJahr > endJahr) {
      result.success = false;
      result.errorMessage = 'Startjahr ($startJahr) muss vor dem Endjahr ($endJahr) liegen.';
      return result;
    }

    if (startJahr < 1955 || endJahr > DateTime.now().year) {
      result.success = false;
      result.errorMessage = 'Jahre müssen zwischen 1955 und ${DateTime.now().year} liegen.';
      return result;
    }

    // 2. Für jedes Jahr im Bereich
    for (int jahr = startJahr; jahr <= endJahr; jahr++) {
      try {
        print('   📅 Verarbeite Jahr $jahr...');
        final jahresErgebnis = await _importEinzelnesJahr(jahr, spieltag);
        
        if (jahresErgebnis.success) {
          gesamtImportiert += jahresErgebnis.importedCount;
        } else {
          fehler.add('$jahr: ${jahresErgebnis.errorMessage}');
        }
      } catch (e) {
        fehler.add('$jahr: Unbekannter Fehler ($e)');
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 3. Erstelle das Endergebnis
    if (gesamtImportiert > 0) {
      result.success = true;
      result.importedCount = gesamtImportiert;
      result.message = 'Erfolgreich $gesamtImportiert Ziehungen aus dem Bereich $startJahr-$endJahr importiert.';
      if (fehler.isNotEmpty) {
        result.message += '\n⚠️ Teilweise Fehler: ${fehler.join(", ")}';
      }
    } else {
      result.success = false;
      result.errorMessage = 'Import fehlgeschlagen.\nFehler: ${fehler.join(", ")}';
    }
    return result;
  }

  // Hilfsfunktion für ein einzelnes Jahr
  Future<ScraperResult> _importEinzelnesJahr(int jahr, String spieltag) async {
    final result = ScraperResult();
    result.success = false;
    result.errorMessage = "❌ Website verwendet JavaScript. Automatischer Import nicht möglich.";
    result.suggestion = "Bitte gehen Sie zu lottozahlenonline.de, wählen Sie ein Jahr, kopieren Sie die Tabelle und fügen Sie sie manuell ein.";
    return result;
  }

  // HTTP Headers
  Map<String, String> _getHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
    };
  }
}

// Ergebnis-Klasse für Scraper-Operationen
class ScraperResult {
  bool success = false;
  int importedCount = 0;
  String message = '';
  String errorMessage = '';
  String suggestion = '';

  @override
  String toString() {
    if (success) {
      return '✅ $message';
    } else {
      return '❌ $errorMessage';
    }
  }
}

  // Manueller Textimport
  Future<ScraperResult> importFromText(String rawText, String spieltyp) async {
    final result = ScraperResult();
    try {
      final lines = rawText.split("\n");
      int counter = 0;
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        final zahlMatches = RegExp(r"\b\d{1,2}\b").allMatches(line);
        final allNumbers = zahlMatches.map((m) => int.tryParse(m.group(0)!) ?? -1)
          .where((n) => n > 0 && n <= 49).toList();
        if (allNumbers.length >= 6) {
          counter++;
          final ziehung = LottoZiehung(
            datum: DateTime.now().subtract(Duration(days: counter * 7)),
            zahlen: allNumbers.sublist(0, 6),
            superzahl: 0,
            spieltyp: spieltyp,
          );
          await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
        }
      }
      result.success = true;
      result.importedCount = counter;
      result.message = "Erfolgreich $counter Ziehungen importiert";
    } catch (e) {
      result.success = false;
      result.errorMessage = "Fehler: $e";
    }
    return result;
  }
