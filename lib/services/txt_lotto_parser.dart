import '../models/lotto_draw.dart';

class TxtLottoParser {
  /// Erwartetes Format (Beispiel 6aus49):
  /// 06.12.2025Sa1526273335372
  ///
  /// Erwartetes Format (Eurojackpot):
  /// 06.12.20251526273335372
  static LottoDraw parseLine(String line, String spieltyp) {
    if (line.length < 14) {
      throw FormatException('Zeile zu kurz: $line');
    }

    // Datum
    final day = int.parse(line.substring(0, 2));
    final month = int.parse(line.substring(3, 5));
    final year = int.parse(line.substring(6, 10));
    final datum = DateTime(year, month, day);

    // Zahlenblock beginnt unterschiedlich
    final numbersStart = spieltyp == '6aus49' ? 12 : 10;
    final numbersRaw = line.substring(numbersStart);

    final zahlen = <int>[];
    for (int i = 0; i + 1 < numbersRaw.length; i += 2) {
      zahlen.add(int.parse(numbersRaw.substring(i, i + 2)));
    }

    zahlen.sort();

    if (spieltyp == '6aus49') {
      final superzahl = zahlen.removeLast();
      return LottoDraw(
        spieltyp: spieltyp,
        datum: datum,
        zahlen: zahlen,
        superzahl: superzahl,
      );
    }

    return LottoDraw(
      spieltyp: spieltyp,
      datum: datum,
      zahlen: zahlen,
      superzahl: null,
    );
  }

  static List<LottoDraw> parseText(String text, String spieltyp) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return lines.map((l) => parseLine(l, spieltyp)).toList();
  }
}
