import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/lotto_data.dart';

class EurojackpotScraper {
  Future<List<LottoZiehung>> ladeJahr(int jahr) async {
    print("[SCRAPER] 🗓️  Lade Eurojackpot-Daten für $jahr");
    final List<LottoZiehung> result = [];

    final url = "https://www.eurojackpot-zahlen.eu/eurojackpot-zahlenarchiv.php?j=$jahr";
    print("[SCRAPER] 📡 URL: $url");

    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        print("[SCRAPER] ❌ HTTP-Fehler: ${resp.statusCode}");
        return result;
      }

      final doc = parse(resp.body);
      print("[SCRAPER] ✅ HTML geladen (${resp.body.length} Zeichen)");

      // NEUE STRUKTUR: Suche nach Datumselementen mit Klasse "zahlenarchiv_datum"
      final datumElements = doc.querySelectorAll('time[class*="zahlenarchiv_datum"]');
      print("[SCRAPER] 🔍 Gefundene Datumselemente: ${datumElements.length}");

      for (final datumElement in datumElements) {
        try {
          // Extrahiere das datetime Attribut
          final datetime = datumElement.attributes['datetime'];
          if (datetime == null || !datetime.contains('-')) continue;

          // Parse Datum
          final dateParts = datetime.split('-');
          if (dateParts.length != 3) continue;

          final year = int.tryParse(dateParts[0]);
          final month = int.tryParse(dateParts[1]);
          final day = int.tryParse(dateParts[2]);

          if (year == null || month == null || day == null) continue;
          final date = DateTime(year, month, day);

          // Prüfe Jahr
          if (date.year != jahr) continue;

          // Finde die zugehörigen Zahlen
          final zahlen = <int>[];

          // Suche nach div-Elementen mit Klasse "zahlenarchiv_zahl" im gleichen Container
          var container = datumElement.parent;
          if (container != null) {
            final zahlElements = container.querySelectorAll('div[class*="zahlenarchiv_zahl"]');
            
            for (final zahlElement in zahlElements) {
              final zahlText = zahlElement.text.trim();
              final zahl = int.tryParse(zahlText);
              if (zahl != null) {
                zahlen.add(zahl);
              }
            }
          }

          // Alternative: Suche im gesamten Dokument-Bereich
          if (zahlen.length < 7) {
            // Gehe zu den nächsten Geschwisterelementen
            var nextElement = datumElement.nextElementSibling;
            int count = 0;
            while (nextElement != null && count < 20) {
              final text = nextElement.text.trim();
              final numbers = _extractAllNumbers(text);
              for (final num in numbers) {
                if (!zahlen.contains(num) && zahlen.length < 7) {
                  zahlen.add(num);
                }
              }
              nextElement = nextElement.nextElementSibling;
              count++;
            }
          }

          // Teile in Hauptzahlen (1-50) und Eurozahlen (1-12)
          if (zahlen.length >= 7) {
            final alleZahlen = List<int>.from(zahlen)..sort();
            
            // Trenne in Haupt- und Eurozahlen basierend auf Bereichen
            final hauptzahlen = <int>[];
            final eurozahlen = <int>[];
            
            for (final zahl in alleZahlen) {
              if (zahl >= 1 && zahl <= 50 && hauptzahlen.length < 5) {
                hauptzahlen.add(zahl);
              } else if (zahl >= 1 && zahl <= 12 && eurozahlen.length < 2) {
                eurozahlen.add(zahl);
              }
            }
            
            // Validiere
            if (hauptzahlen.length == 5 && eurozahlen.length == 2) {
              hauptzahlen.sort();
              eurozahlen.sort();
              
              result.add(
                LottoZiehung(
                  datum: date,
                  spieltyp: "Eurojackpot",
                  zahlen: [...hauptzahlen, ...eurozahlen],
                  superzahl: 0,
                ),
              );
              
              if (result.length % 10 == 0) {
                print("[SCRAPER] 📊 Fortschritt: ${result.length} Ziehungen gefunden");
              }
            }
          }
        } catch (e) {
          print("[SCRAPER] ⚠️  Fehler beim Parsen eines Elements: $e");
        }
      }

      print("[SCRAPER] ✅ Erfolgreich geparst: ${result.length} Ziehungen für $jahr");
      
      // Fallback
      if (result.isEmpty) {
        print("[SCRAPER] ⚠️  Keine Daten mit neuem Parser, versuche alten Ansatz...");
        return _fallbackParse(doc, jahr);
      }

    } catch (e) {
      print("[SCRAPER] ❌ Kritischer Fehler: $e");
    }

    return result;
  }

  // Fallback-Parser
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
        
        if (date != null && zahlen.length >= 7 && date.year == jahr) {
          result.add(
            LottoZiehung(
              datum: date,
              spieltyp: "Eurojackpot",
              zahlen: zahlen,
              superzahl: 0,
            ),
          );
        }
      }
    }
    
    return result;
  }

  List<int> _extractAllNumbers(String text) {
    return RegExp(r'\b\d{1,2}\b')
        .allMatches(text)
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>()
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
