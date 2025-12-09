import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/lotto_data.dart';

class WebScraper {
  Future<List<LottoZiehung>> scrapeLottozahlenOnline(int jahr) async {
    final url = Uri.parse(
        'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php?j=$jahr');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return _parseHtml(response.body, jahr);
      } else {
        print('HTTP Fehler: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Scraper Fehler: $e');
      return [];
    }
  }

  List<LottoZiehung> _parseHtml(String html, int jahr) {
    final ziehungen = <LottoZiehung>[];
    final doc = parser.parse(html);
    final rows = doc.querySelectorAll("table.archiv tbody tr");

    int maxZahl = 0; // Initialisierung
    
    for (final row in rows) {
      final cols = row.querySelectorAll("td");
      if (cols.length < 2) continue;

      final rawDate = cols[0].text.trim();
      final zahlenString = cols[1].text.trim();

      final zahlen = zahlenString
          .split(" ")
          .where((x) => x.isNotEmpty)
          .map((e) => int.tryParse(e) ?? 0)
          .where((zahl) => zahl > 0) // Filtere ungültige Zahlen
          .toList();

      if (zahlen.length < 6) continue;

      // Finde Maximum für Debugging
      for (final zahl in zahlen) {
        if (zahl > maxZahl) {
          maxZahl = zahl;
        }
      }

      final superzahl = zahlen.length >= 7 ? zahlen.last : 0;
      final hauptzahlen = zahlen.length >= 7 
          ? zahlen.sublist(0, 6) 
          : zahlen;

      ziehungen.add(LottoZiehung(
        datum: LottoZiehung.parseDatum(rawDate),
        zahlen: hauptzahlen,
        superzahl: superzahl,
        spieltyp: "6aus49",
      ));
    }

    print('Maximale Zahl gefunden: $maxZahl');
    return ziehungen;
  }

  Future<void> importiereJahr(int jahr) async {
    final ziehungen = await scrapeLottozahlenOnline(jahr);
    if (ziehungen.isNotEmpty) {
      // Importiere die Ziehungen in die Datenbank
      // Dies muss mit deiner Datenbank-Logik verbunden werden
      print('${ziehungen.length} Ziehungen für $jahr gefunden');
    }
  }
}
