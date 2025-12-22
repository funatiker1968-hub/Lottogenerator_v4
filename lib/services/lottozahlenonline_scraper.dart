import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/lotto_data.dart';

class LottozahlenOnlineScraper {
  final String spieltyp;

  LottozahlenOnlineScraper(this.spieltyp);

  Future<List<LottoZiehung>> ladeJahr(int jahr) async {
    print("[SCRAPER] 🗓️  Lade Lotto-Daten für $jahr");
    final List<LottoZiehung> result = [];

    final url = "https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php?j=$jahr";
    print("[SCRAPER] 📡 URL: $url");

    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        print("[SCRAPER] ❌ HTTP-Fehler: ${resp.statusCode}");
        return result;
      }

      final doc = parse(resp.body);
      print("[SCRAPER] ✅ HTML geladen (${resp.body.length} Zeichen)");

      // NEUE STRUKTUR: Suche nach Datumselementen mit Klasse "zahlensuche_datum"
      final datumElements = doc.querySelectorAll('time[datetime]');
      print("[SCRAPER] 🔍 Gefundene Datumselemente: ${datumElements.length}");

      for (final datumElement in datumElements) {
        try {
          // Extrahiere das datetime Attribut
          final datetime = datumElement.attributes['datetime'];
          if (datetime == null || !datetime.contains('-')) continue;

          // Parse Datum (Format: yyyy-mm-dd)
          final dateParts = datetime.split('-');
          if (dateParts.length != 3) continue;

          final year = int.tryParse(dateParts[0]);
          final month = int.tryParse(dateParts[1]);
          final day = int.tryParse(dateParts[2]);

          if (year == null || month == null || day == null) continue;
          final date = DateTime(year, month, day);

          // Prüfe ob das Datum zum gesuchten Jahr gehört
          if (date.year != jahr) continue;

          // Finde die zugehörigen Zahlen
          // Die Zahlen sind in div-Elementen nach dem time-Element
          final zahlen = <int>[];

          // Gehe zum übergeordneten Container und suche Zahlenelemente
          var parent = datumElement.parent;
          if (parent != null) {
            // Suche nach div-Elementen mit Zahlen
            final zahlElements = parent.querySelectorAll('div[class*="zahl"]');
            
            for (final zahlElement in zahlElements) {
              final zahlText = zahlElement.text.trim();
              final zahl = int.tryParse(zahlText);
              if (zahl != null && zahl >= 1 && zahl <= 49) {
                zahlen.add(zahl);
              }
            }
          }

          // Alternative: Suche im gesamten Kontext
          if (zahlen.length < 6) {
            // Versuche einen anderen Ansatz: Suche im nächsten Geschwisterelement
            var nextElement = datumElement.nextElementSibling;
            while (nextElement != null && zahlen.length < 6) {
              final text = nextElement.text.trim();
              final numbersInText = _extractNumbers(text);
              for (final num in numbersInText) {
                if (num >= 1 && num <= 49 && !zahlen.contains(num) && zahlen.length < 6) {
                  zahlen.add(num);
                }
              }
              nextElement = nextElement.nextElementSibling;
            }
          }

          // Superzahl (letzte Zahl oder spezielles Element)
          int superzahl = 0;
          if (zahlen.length > 6) {
            superzahl = zahlen.last;
            zahlen.removeLast();
          }

          // Validiere die gefundenen Zahlen
          if (zahlen.length == 6) {
            // Sortiere die Zahlen
            zahlen.sort();

            // Erstelle LottoZiehung
            result.add(
              LottoZiehung(
                datum: date,
                spieltyp: "6aus49",
                zahlen: List.from(zahlen),
                superzahl: superzahl,
              ),
            );

            if (result.length % 10 == 0) {
              print("[SCRAPER] 📊 Fortschritt: ${result.length} Ziehungen gefunden");
            }
          }
        } catch (e) {
          print("[SCRAPER] ⚠️  Fehler beim Parsen eines Elements: $e");
        }
      }

      print("[SCRAPER] ✅ Erfolgreich geparst: ${result.length} Ziehungen für $jahr");
      
      // Fallback: Wenn keine Daten gefunden wurden, versuche alten Parser
      if (result.isEmpty) {
        print("[SCRAPER] ⚠️  Keine Daten mit neuem Parser, versuche alten Ansatz...");
        return _fallbackParse(doc, jahr);
      }

    } catch (e) {
      print("[SCRAPER] ❌ Kritischer Fehler: $e");
    }

    return result;
  }

  // Fallback-Parser für alte Tabellen-Struktur
  List<LottoZiehung> _fallbackParse(var doc, int jahr) {
    final result = <LottoZiehung>[];
    
    final rows = doc.querySelectorAll("tr");
    for (final row in rows) {
      final cols = row.querySelectorAll("td");
      if (cols.length >= 3) {
        final datumText = cols[0].text.trim();
        final zahlenText = cols[1].text.trim();
        
        final date = _parseDatum(datumText);
        final zahlen = _parseZahlen(zahlenText);
        
        if (date != null && zahlen.length >= 6 && date.year == jahr) {
          final superzahl = zahlen.length > 6 ? zahlen[6] : 0;
          result.add(
            LottoZiehung(
              datum: date,
              spieltyp: "6aus49",
              zahlen: zahlen.take(6).toList(),
              superzahl: superzahl,
            ),
          );
        }
      }
    }
    
    return result;
  }

  List<int> _extractNumbers(String text) {
    return RegExp(r'\b\d{1,2}\b')
        .allMatches(text)
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>()
        .where((num) => num >= 1 && num <= 49)
        .toList();
  }

  DateTime? _parseDatum(String input) {
    try {
      final p = input.split('.');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return null;
    }
  }

  List<int> _parseZahlen(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9 ]'), '');
    return cleaned
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }
}
