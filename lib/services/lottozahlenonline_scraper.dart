import 'package:http/http.dart' as http;
import '../models/lotto_data.dart';

class LottozahlenOnlineScraper {
  final String spieltyp;

  LottozahlenOnlineScraper(this.spieltyp);

  Future<List<LottoZiehung>> ladeJahr(int jahr) async {
    final List<LottoZiehung> result = [];
    final url = _buildUrl(jahr);

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      print("Fehler HTTP ${resp.statusCode} bei $url");
      return result;
    }

    final html = resp.body;

    if (spieltyp == "6aus49") {
      _parseLotto(html, jahr, result);
    } else if (spieltyp == "Eurojackpot") {
      _parseEuro(html, jahr, result);
    }

    return result;
  }

  String _buildUrl(int jahr) {
    if (spieltyp == "6aus49") {
      return "https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php?j=$jahr";
    }
    if (spieltyp == "Eurojackpot") {
      return "https://www.eurojackpot-zahlen.eu/eurojackpot-zahlenarchiv.php?j=$jahr";
    }
    throw Exception("Unbekannter Spieltyp: $spieltyp");
  }

  // ----------------------------------------------------------
  //  LOTTO 6aus49  PARSER  (Regex)
  // ----------------------------------------------------------
  void _parseLotto(String html, int jahr, List<LottoZiehung> out) {
    final exp = RegExp(
      r'(\d{2}\.\d{2}\.' + jahr.toString() +
          r').*?(\d{1,2})\s+(\d{1,2})\s+(\d{1,2})\s+(\d{1,2})\s+(\d{1,2})\s+(\d{1,2})\s*\(SZ\s*(\d)\)',
      dotAll: true,
    );

    for (final m in exp.allMatches(html)) {
      final datum = _parseDatum(m.group(1)!);
      final zahlen = [
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
        int.parse(m.group(7)!),
      ];

      final sz = int.parse(m.group(8)!);

      out.add(LottoZiehung(
        datum: datum,
        spieltyp: "6aus49",
        zahlen: zahlen,
        superzahl: sz,
      ));
    }
  }

  // ----------------------------------------------------------
  //  EUROJACKPOT  PARSER  (Regex)
  // ----------------------------------------------------------
  void _parseEuro(String html, int jahr, List<LottoZiehung> out) {
    final exp = RegExp(
      r'(\d{2}\.\d{2}\.' + jahr.toString() +
          r').*?(\d{1,2})\s+(\d{1,2})\s+(\d{1,2})\s+(\d{1,2})\s+(\d{1,2}).*?Eurozahlen:\s*(\d{1,2})\s+(\d{1,2})',
      dotAll: true,
    );

    for (final m in exp.allMatches(html)) {
      final datum = _parseDatum(m.group(1)!);

      final zahlen = [
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
        int.parse(m.group(7)!), // Eurozahl 1
        int.parse(m.group(8)!), // Eurozahl 2
      ];

      out.add(LottoZiehung(
        datum: datum,
        spieltyp: "Eurojackpot",
        zahlen: zahlen,
        superzahl: 0,
      ));
    }
  }

  DateTime _parseDatum(String input) {
    final p = input.split(".");
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }
}
