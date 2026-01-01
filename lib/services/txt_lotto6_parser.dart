import 'dart:core';

class LottoDraw {
  final DateTime date;
  final List<int> numbers; // immer 6
  final int? superzahl; // null bei alten Ziehungen

  LottoDraw({
    required this.date,
    required this.numbers,
    this.superzahl,
  });
}

class TxtLotto6Parser {
  /// Parst eine komplette TXT-Datei (Zeile für Zeile)
  /// Unterstützt:
  /// - alte Ziehungen OHNE Superzahl
  /// - neue Ziehungen MIT oder OHNE Superzahl
  /// - verschiedene Trennzeichen (Leerzeichen, ; , Tab)
  static List<LottoDraw> parse(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final result = <LottoDraw>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final draw = _parseLine(line);
      if (draw != null) {
        result.add(draw);
      }
    }

    return result;
  }

  /// Parst eine einzelne Zeile
  static LottoDraw? _parseLine(String line) {
    // Alle Zahlen extrahieren (Datum + Ziehungszahlen)
    final matches = RegExp(r'\d+').allMatches(line).map((m) => m.group(0)!).toList();

    // Minimum: Datum (3 Zahlen) + 6 Lottozahlen = 9
    if (matches.length < 9) return null;

    // Datum erkennen
    final date = _parseDate(matches);
    if (date == null) return null;

    // Restliche Zahlen nach Datum
    final numbersPart = matches.skip(3).map(int.parse).toList();
    if (numbersPart.length < 6) return null;

    final mainNumbers = numbersPart.take(6).toList();
    if (mainNumbers.length != 6) return null;

    int? superzahl;

    // Superzahl nur ab 1991 UND wenn vorhanden
    if (date.year >= 1991 && numbersPart.length >= 7) {
      superzahl = numbersPart[6];
    }

    return LottoDraw(
      date: date,
      numbers: mainNumbers,
      superzahl: superzahl,
    );
  }

  /// Erkennt Datum aus den ersten drei Zahlen
  /// Unterstützt:
  /// - DD MM YYYY
  /// - YYYY MM DD
  static DateTime? _parseDate(List<String> parts) {
    final a = int.parse(parts[0]);
    final b = int.parse(parts[1]);
    final c = int.parse(parts[2]);

    // YYYY-MM-DD
    if (a > 1900 && b >= 1 && b <= 12 && c >= 1 && c <= 31) {
      return DateTime(a, b, c);
    }

    // DD-MM-YYYY
    if (c > 1900 && b >= 1 && b <= 12 && a >= 1 && a <= 31) {
      return DateTime(c, b, a);
    }

    return null;
  }
}
