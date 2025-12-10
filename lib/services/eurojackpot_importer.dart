import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlparser;
import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

/// Importiert Eurojackpot-Ziehungen von 2012 bis heute.
class EurojackpotImporter {
  /// Importiert alle Jahre 2012–heute.
  static Future<void> importiereAlles(Function(String) log) async {
    final int startJahr = 2012;
    final int endeJahr = DateTime.now().year;

    log("Starte Eurojackpot-Import $startJahr–$endeJahr ...");

    for (int jahr = startJahr; jahr <= endeJahr; jahr++) {
      await _importiereJahr(jahr, log);
    }

    log("Eurojackpot-Import abgeschlossen!");
  }

  /// Importiert ein einzelnes Jahr.
  static Future<void> _importiereJahr(int jahr, Function(String) log) async {
    final url =
        "https://www.eurojackpot-zahlen.eu/eurojackpot-zahlenarchiv.php?j=$jahr";

    log("Hole Daten für $jahr ...");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      log("⚠️ Fehler beim Laden von Jahr $jahr (HTTP ${response.statusCode})");
      return;
    }

    final document = htmlparser.parse(response.body);

    // Tabelle finden (erste Tabelle auf der Seite)
    final table = document.querySelector("table");
    if (table == null) {
      log("⚠️ Keine Tabelle gefunden für Jahr $jahr.");
      return;
    }

    final rows = table.querySelectorAll("tr");
    log("→ ${rows.length - 1} Ziehungen gefunden.");

    // Erste Zeile = Header → überspringen
    for (int i = 1; i < rows.length; i++) {
      final cells = rows[i].querySelectorAll("td");
      if (cells.length < 8) continue;

      try {
        // Datum parse
        final datumStr = cells[0].text.trim();
        final datum = _parseDatum(datumStr);

        // 5 Hauptzahlen
        final zahlen = [
          int.parse(cells[1].text.trim()),
          int.parse(cells[2].text.trim()),
          int.parse(cells[3].text.trim()),
          int.parse(cells[4].text.trim()),
          int.parse(cells[5].text.trim()),
        ];

        // 2 Eurozahlen
        zahlen.add(int.parse(cells[6].text.trim()));
        zahlen.add(int.parse(cells[7].text.trim()));

        final ziehung = LottoZiehung(
          datum: datum,
          spieltyp: "Eurojackpot",
          zahlen: zahlen,
          superzahl: 0,
        );

        // Prüfen + Einfügen
        final schon = await ErweiterteLottoDatenbank.pruefeObSchonVorhanden(
            "Eurojackpot", datum);

        if (!schon) {
          await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(ziehung);
          log("✔️ ${datum.toIso8601String()} gespeichert");
        } else {
          log("… ${datum.toIso8601String()} bereits vorhanden");
        }
      } catch (e) {
        log("⚠️ Fehler beim Verarbeiten einer Ziehung: $e");
      }
    }

    log("Jahr $jahr fertig.");
  }

  /// Datum parsen: z.B. "03.01.2014"
  static DateTime _parseDatum(String s) {
    final parts = s.split(".");
    final tag = int.parse(parts[0]);
    final monat = int.parse(parts[1]);
    final jahr = int.parse(parts[2]);
    return DateTime(jahr, monat, tag);
  }
}
