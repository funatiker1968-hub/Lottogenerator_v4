import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final int jahr = 2025;
  final url = Uri.parse('https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php?j=\$jahr#lottozahlen-archiv');

  final resp = await http.get(
    url,
    headers: {
      'User-Agent': 'Mozilla/5.0',
      'Accept': 'text/html',
    },
  );

  if (resp.statusCode != 200) {
    print('❌ HTTP-Fehler bei \$jahr: \${resp.statusCode}');
    return;
  }

  final doc = parser.parse(resp.body);
  final tables = doc.querySelectorAll('table');
  Element? ziel;
  for (var t in tables) {
    final txt = t.text;
    if (txt.contains('Datum') && txt.contains('Gewinnzahlen')) {
      ziel = t;
      break;
    }
  }

  if (ziel == null) {
    print('❌ Keine passende Tabelle gefunden für Jahr \$jahr.');
    return;
  }

  final rows = ziel.querySelectorAll('tr');
  final List<LottoZiehung> ziehungen = [];
  for (var row in rows.skip(1)) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 10) continue;

    final dateStr = cells[1].text.trim();
    final datum = _parseDatum(dateStr);
    if (datum == null) continue;

    final numbers = <int>[];
    bool ok = true;
    for (int i = 3; i < 9; i++) {
      final n = int.tryParse(cells[i].text.trim());
      if (n == null) { ok = false; break; }
      numbers.add(n);
    }
    if (!ok || numbers.length != 6) continue;

    final superzahl = int.tryParse(cells[9].text.trim());
    if (superzahl == null) continue;

    ziehungen.add(LottoZiehung(
      datum: datum,
      zahlen: numbers,
      superzahl: superzahl,
      spieltyp: '6aus49',
    ));
  }

  print('ℹ️ Gefundene Ziehungen: \${ziehungen.length}');
  final inserted = await ErweiterteLottoDatenbank.fuegeZiehungenHinzu(ziehungen);
  print('✅ Import abgeschlossen: neue Einträge = \$inserted');
}

DateTime? _parseDatum(String ds) {
  if (ds.length != 10 || ds[2] != '.' || ds[5] != '.') return null;
  final d = int.tryParse(ds.substring(0, 2));
  final m = int.tryParse(ds.substring(3, 5));
  final y = int.tryParse(ds.substring(6, 10));
  if (d == null || m == null || y == null) return null;
  return DateTime(y, m, d);
}
