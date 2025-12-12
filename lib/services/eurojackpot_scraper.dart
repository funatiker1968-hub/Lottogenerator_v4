import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/lotto_data.dart';

class EurojackpotScraper {
  Future<List<LottoZiehung>> ladeJahr(int jahr) async {
    final List<LottoZiehung> result = [];

    final url = "https://www.eurojackpot-zahlen.eu/eurojackpot-zahlenarchiv.php?j=$jahr";

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      print("Fehler beim Laden der Eurojackpot-Seite: ${resp.statusCode}");
      return result;
    }

    final doc = parse(resp.body);

    final rows = doc.querySelectorAll("table tbody tr");
    for (final row in rows) {
      final cols = row.querySelectorAll("td");
      if (cols.length < 3) continue;

      final datumText = cols[0].text.trim();
      final zahlenText = cols[1].text.trim();

      final date = _parseDatum(datumText);
      final zahlen = _parseZahlen(zahlenText);

      if (date == null || zahlen.length < 7) continue;

      final haupt = zahlen.take(5).toList();
      final euro = zahlen.skip(5).take(2).toList();

      result.add(
        LottoZiehung(
          datum: date,
          spieltyp: "Eurojackpot",
          zahlen: [...haupt, ...euro],
          superzahl: 0,
        ),
      );
    }

    return result;
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
        .map(int.parse)
        .toList();
  }
}
