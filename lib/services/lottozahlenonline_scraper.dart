import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

class LottoZahlenonlineScraper {
  static const String _baseUrl =
      'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php';

  /// Importiere alle Ziehungen eines Jahres (6aus49) und speichere sie in der DB.
  /// Gibt zurück, wie viele neue Ziehungen eingefügt wurden.
  static Future<int> importiereJahr(int jahr) async {
    final uri = Uri.parse('$_baseUrl?j=\$jahr#lottozahlen-archiv');
    final resp = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0',
      'Accept': 'text/html',
    });
    if (resp.statusCode != 200) {
      print('❌ HTTP-Fehler für Jahr \$jahr: \${resp.statusCode}');
      return 0;
    }

    final doc = parser.parse(resp.body);
    TableElement? t = doc.querySelectorAll('table').cast<TableElement?>().firstWhere(
      (tbl) => tbl != null &&
               tbl.text.contains('Datum') &&
               tbl.text.contains('Gewinnzahlen'),
      orElse: () => null,
    );
    if (t == null) {
      print('⚠️ Keine passende Tabelle gefunden für Jahr \$jahr — evtl. geändertes Seitenformat');
      return 0;
    }

    int imported = 0;
    for (final row in t.querySelectorAll('tr').skip(1)) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 10) continue;

      final dateStr = cells[1].text.trim(); // z.B. "01.01.2025"
      final parts = dateStr.split('.');
      if (parts.length != 3) continue;
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) continue;
      final datum = DateTime(year, month, day);

      final zahlen = <int>[];
      bool ok = true;
      for (int i = 3; i < 9; i++) {
        final n = int.tryParse(cells[i].text.trim());
        if (n == null) { ok = false; break; }
        zahlen.add(n);
      }
      if (!ok || zahlen.length != 6) continue;

      final superZ = int.tryParse(cells[9].text.trim());
      if (superZ == null) continue;

      final ziehung = LottoZiehung(
        datum: datum,
        zahlen: zahlen,
        superzahl: superZ,
        spieltyp: '6aus49',
      );
      final res = await ErweiterteLottoDatenbank.fuegeZiehungHinzu(ziehung);
      if (res > 0) imported++;
    }

    print('Jahr \$jahr: \$imported neue Ziehungen importiert');
    return imported;
  }

  /// Importiere alle Jahre im Bereich [startJahr..endJahr] (inklusiv)
  static Future<int> importiereZeitraum(int startJahr, int endJahr) async {
    int total = 0;
    for (int j = startJahr; j <= endJahr; j++) {
      total += await importiereJahr(j);
      // Optional: kleine Pause, um Server nicht zu überlasten
      await Future.delayed(const Duration(milliseconds: 200));
    }
    print('✅ Gesamt importiert: \$total Ziehungen (Jahre \$startJahr–\$endJahr)');
    return total;
  }
}
