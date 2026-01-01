import 'dart:io';
import '../models/lotto_draw.dart';

class TxtLottoParser {
  static final DateTime superzahlStart =
      DateTime(1991, 12, 7); // historisch korrekt

  /// Liest assets/data/lotto_1955_2025.txt
  static List<LottoDraw> parseLotto1955_2025(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('TXT-Datei nicht gefunden: $path');
    }

    final lines = file.readAsLinesSync();
    final draws = <LottoDraw>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Erwartet: DD.MM.YYYY | 1 2 3 4 5 6 | X
      final parts = line.split('|');
      if (parts.length < 2) continue;

      final datePart = parts[0].trim();
      final numbersPart = parts[1].trim();
      final extraPart = parts.length >= 3 ? parts[2].trim() : '';

      // Datum
      final d = datePart.split('.');
      if (d.length != 3) continue;

      final date = DateTime(
        int.parse(d[2]),
        int.parse(d[1]),
        int.parse(d[0]),
      );

      // Zahlen
      final numbers = numbersPart
          .split(' ')
          .where((e) => e.trim().isNotEmpty)
          .map(int.parse)
          .toList();

      if (numbers.length != 6) continue;

      // Superzahl
      int extra = -1;
      if (date.isAfter(superzahlStart) ||
          date.isAtSameMomentAs(superzahlStart)) {
        if (extraPart.isNotEmpty) {
          extra = int.parse(extraPart);
        }
      }

      draws.add(
        LottoDraw(
          date: date,
          numbers: numbers,
          extra: extra,
        ),
      );
    }

    return draws;
  }
}
