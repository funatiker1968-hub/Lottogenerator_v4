import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/lotto_data.dart';

class LottozahlenOnlineScraper {
  final String spieltyp;

  LottozahlenOnlineScraper(this.spieltyp);

  /// Lädt alle Ziehungen eines Jahres über lotto.de
  Future<List<LottoZiehung>> ladeJahr(int jahr) async {
    final List<LottoZiehung> result = [];

    final url = _buildUrl(jahr);
    final resp = await http.get(Uri.parse(url));

    if (resp.statusCode != 200) {
      print("Fehler beim Laden: ${resp.statusCode}");
      return result;
    }

    final document = parse(resp.body);
    final rows = document.querySelectorAll("table tbody tr");

    for (final r in rows) {
      final cols = r.querySelectorAll("td");
      if (cols.length < 3) continue;

      final datumText = cols[0].text.trim();
      final zahlenText = cols[1].text.trim();

      final date = _parseDatum(datumText);
      final zahlen = _parseZahlen(zahlenText);

      if (date != null && zahlen.isNotEmpty) {
        result.add(LottoZiehung(
          datum: date,
          spieltyp: spieltyp,
          zahlen: zahlen,
          superzahl: zahlen.length > 6 ? zahlen.last : 0,
        ));
      }
    }

    return result;
  }

  /// URL je nach Spieltyp
  String _buildUrl(int jahr) {
    if (spieltyp == "6aus49") {
      return "https://www.lotto.de/lotto-6aus49/archiv-${jahr}";
    } else if (spieltyp == "Eurojackpot") {
      return "https://www.lotto.de/eurojackpot/archiv-${jahr}";
    }
    throw Exception("Unbekannter Spieltyp: $spieltyp");
  }

  /// Datum im Format 01.02.2023 → DateTime
  DateTime? _parseDatum(String input) {
    try {
      final parts = input.split('.');
      if (parts.length != 3) return null;

      final tag = int.parse(parts[0]);
      final mon = int.parse(parts[1]);
      final jahr = int.parse(parts[2]);

      return DateTime(jahr, mon, tag);
    } catch (_) {
      return null;
    }
  }

  /// Zahlenliste „1 2 3 4 5 6 (SZ 7)“
  List<int> _parseZahlen(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9 ]'), '');
    return cleaned
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .map(int.parse)
        .toList();
  }
}
