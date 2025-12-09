// lib/services/lottozahlenonline_scraper.dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

class ScraperResult {
  final bool success;
  final int importedCount;
  final String message;
  final String errorMessage;

  ScraperResult({
    this.success = false,
    this.importedCount = 0,
    this.message = '',
    this.errorMessage = '',
  });

  @override
  String toString() {
    if (success) {
      return '✅ \$message';
    } else {
      return '❌ \$errorMessage';
    }
  }
}

class LottoOnlineScraper {
  static const String _baseUrl =
      'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php';

  static Future<ScraperResult> importRange({
    required int startJahr,
    required int endJahr,
    String spieltyp = '6aus49',
  }) async {
    if (startJahr > endJahr) {
      return ScraperResult(
        success: false,
        errorMessage: 'Startjahr (\$startJahr) muss ≤ Endjahr (\$endJahr) sein.',
      );
    }
    final current = DateTime.now().year;
    if (startJahr < 1955 || endJahr > current) {
      return ScraperResult(
        success: false,
        errorMessage:
            'Jahre müssen zwischen 1955 und \$current liegen.',
      );
    }

    int total = 0;
    List<String> errs = [];

    for (int year = startJahr; year <= endJahr; year++) {
      final res = await _importYear(year, spieltyp);
      if (res.success) {
        total += res.importedCount;
      } else {
        errs.add('Jahr \$year: \${res.errorMessage}');
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (total > 0) {
      return ScraperResult(
        success: true,
        importedCount: total,
        message: 'Import abgeschlossen: \$total Ziehungen importiert.' +
            (errs.isNotEmpty ? '\\n⚠️ Teilweise Fehler: \${errs.join("; ")}' : ''),
      );
    } else {
      return ScraperResult(
        success: false,
        errorMessage: 'Import fehlgeschlagen.' +
            (errs.isNotEmpty ? '\\nFehler: \${errs.join("; ")}' : ''),
      );
    }
  }

  static Future<ScraperResult> _importYear(int year, String spieltyp) async {
    final uri = Uri.parse('\$_baseUrl?j=\$year#lottozahlen-archiv');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        return ScraperResult(
          success: false,
          errorMessage: 'HTTP-Fehler \${resp.statusCode} für Jahr \$year',
        );
      }

      final doc = parse(resp.body);
      final tables = doc.getElementsByTagName('table');
      if (tables.isEmpty) {
        return ScraperResult(
          success: false,
          errorMessage:
              'Keine Tabelle im HTML gefunden für Jahr \$year – evtl. Struktur geändert.',
        );
      }

      final table = tables.first;
      final rows = table.getElementsByTagName('tr').skip(1);

      List<LottoZiehung> ziehungen = [];

      for (final row in rows) {
        final cells = row.getElementsByTagName('td');
        if (cells.length < 10) continue;

        final dateStr = cells[1].text.trim();
        List<int> numbers = [];
        bool ok = true;
        for (int i = 3; i < 9; i++) {
          final t = cells[i].text.trim();
          final n = int.tryParse(t);
          if (n == null) {
            ok = false;
            break;
          }
          numbers.add(n);
        }
        if (!ok || numbers.length != 6) continue;

        final superStr = cells[9].text.trim();
        final szz = int.tryParse(superStr);
        if (szz == null) continue;

        final parts = dateStr.split('.');
        if (parts.length != 3) continue;
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d == null || m == null || y == null) continue;
        final date = DateTime(y, m, d);

        ziehungen.add(LottoZiehung(
          datum: date,
          zahlen: numbers,
          superzahl: szz,
          spieltyp: spieltyp,
        ));
      }

      final inserted = await ErweiterteLottoDatenbank.fuegeZiehungenHinzu(ziehungen);
      return ScraperResult(
        success: true,
        importedCount: inserted,
        message: 'Jahr \$year: \$inserted neue Einträge.',
      );
    } catch (e) {
      return ScraperResult(
        success: false,
        errorMessage: 'Fehler bei Jahr \$year: \$e',
      );
    }
  }
}
