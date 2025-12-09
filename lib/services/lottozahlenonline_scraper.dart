import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import '../models/lotto_data.dart';
import 'lotto_import_safe.dart';

class LottozahlenOnlineScraper {
  final LottoImportSafe importer;

  LottozahlenOnlineScraper(this.importer);

  Future<void> ladeJahr(int jahr) async {
    final url =
        "https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php?j=$jahr";

    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) return;

    final doc = parser.parse(r.body);
    final rows = doc.querySelectorAll("table.archiv tbody tr");

    final liste = <LottoZiehung>[];

    for (final row in rows) {
      final cols = row.querySelectorAll("td");
      if (cols.length < 2) continue;

      final rawDate = cols[0].text.trim();
      final zahlenString = cols[1].text.trim();

      final zahlen = zahlenString
          .split(" ")
          .where((x) => x.isNotEmpty)
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      if (zahlen.length < 7) continue;

      liste.add(LottoZiehung(
        datum: LottoZiehung.parseDatum(rawDate),
        zahlen: zahlen,
        superzahl: zahlen.last,
        spieltyp: "6aus49", // später automatisieren
      ));
    }

    await importer.fuegeZiehungenEin(liste);
  }
}
