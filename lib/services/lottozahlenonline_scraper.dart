import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/lotto_data.dart';
import 'lotto_database.dart';

class LottozahlenOnlineScraper {
  // Importiert einen Jahresbereich von lottozahlenonline.de
  Future<ScraperResult> importJahresBereich({
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
      // Kurze Pause, um die Website nicht zu überlasten
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 3. Erstelle das Endergebnis
    if (gesamtImportiert > 0) {
      result.success = true;
      result.importedCount = gesamtImportiert;
      result.message = 'Erfolgreich $gesamtImportiert Ziehungen aus $startJahr-$endJahr importiert.';
      if (fehler.isNotEmpty) {
        result.message += ' (Teilweise Fehler: ${fehler.join(", ")})';
      }
    } else {
      result.success = false;
      result.errorMessage = 'Import fehlgeschlagen. Fehler: ${fehler.join(", ")}';
    }
    return result;
  }

  // Hilfsfunktion: Importiert EIN einzelnes Jahr
  Future<ScraperResult> _importEinzelnesJahr(int jahr, String spieltag) async {
    final result = ScraperResult();
    try {
      // 1. URL bauen
      String baseUrl;
      switch (spieltag) {
        case 'samstag':
          baseUrl = 'https://www.lottozahlenonline.de/statistik/lotto-am-samstag/lottozahlen-archiv.php';
          break;
        case 'mittwoch':
          baseUrl = 'https://www.lottozahlenonline.de/statistik/lotto-am-mittwoch/lottozahlen-archiv.php';
          break;
        case 'beide':
        default:
          baseUrl = 'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php';
      }
      final url = '$baseUrl?year=$jahr';
      print('      📡 Lade: $url');

      // 2. Webseite abrufen
      final response = await http.get(Uri.parse(url), headers: _getHeaders());
      if (response.statusCode != 200) {
        result.errorMessage = 'HTTP-Fehler ${response.statusCode}';
        return result;
      }

      // 3. HTML parsen
      final document = parser.parse(response.body);
      final ziehungen = <LottoZiehung>[];

      // 4. Die richtige Tabelle finden (enthält "Datum" und "SZ")
      final tabellen = document.querySelectorAll('table');
      var zielTabelle = tabellen.firstWhere(
        (t) => t.text.contains('Datum') && t.text.contains('SZ'),
        orElse: () => parser.parse('<table></table>').querySelector('table')!
      );
      
      if (zielTabelle.children.isEmpty) {
        result.errorMessage = 'Tabelle nicht gefunden';
        return result;
      }

      // 5. Zeilen der Tabelle durchgehen (erste Zeile ist die Kopfzeile)
      final zeilen = zielTabelle.querySelectorAll('tr').skip(1);
      for (var row in zeilen) {
        final zellen = row.querySelectorAll('td');
        // Wir erwarten Zellen: [Nr?, Datum, Zahl1, Zahl2, Zahl3, Zahl4, Zahl5, Zahl6, Superzahl, ...]
        if (zellen.length >= 9) {
          try {
            final datumText = zellen[1].text.trim(); // Zelle 1 = Datum
            final superzahlText = zellen[8].text.trim(); // Zelle 8 = Superzahl
            final lottozahlen = <int>[];
            // Zellen 2-7 sind die 6 Lottozahlen
            for (int i = 2; i <= 7; i++) {
              lottozahlen.add(int.parse(zellen[i].text.trim()));
            }
            // Datum umwandeln (DD.MM.JJJJ)
            final dateParts = datumText.split('.');
            final datum = DateTime(
              int.parse(dateParts[2]), // Jahr
              int.parse(dateParts[1]), // Monat
              int.parse(dateParts[0]), // Tag
            );
            // Superzahl
            final superzahl = int.parse(superzahlText);
            // Zur Liste hinzufügen
            ziehungen.add(LottoZiehung(
              datum: datum,
              zahlen: lottozahlen,
              superzahl: superzahl,
              spieltyp: '6aus49',
            ));
          } catch (e) {
            // Fehler in einer Zeile ignorieren und mit der nächsten fortfahren
            print('      ⚠️ Zeilen-Parsingfehler: $e');
          }
        }
      }

      // 6. Gefundene Ziehungen in die Datenbank speichern
      if (ziehungen.isNotEmpty) {
        for (var ziehung in ziehungen) {
          await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
        }
        result.success = true;
        result.importedCount = ziehungen.length;
        print('      ✅ $jahr: ${ziehungen.length} Ziehungen gespeichert.');
      } else {
        result.errorMessage = 'Keine Ziehungen in der Tabelle gefunden';
      }
    } catch (e) {
      result.errorMessage = 'Ausnahme: $e';
    }
    return result;
  }

  // HTTP Headers für bessere Akzeptanz
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
