import 'txt_lotto_parser.dart';

///
/// Eurojackpot TXT Parser
/// Format:
/// YYYY-MM-DD | n n n n n | e e
///
ParserResult parseEurojackpotTxt(String text) {
  int valid = 0;
  int errors = 0;

  final lines = text.split('\n');

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    try {
      final parts = line.split('|');
      if (parts.length != 3) {
        errors++;
        continue;
      }

      // Datum
      final date = parts[0].trim();
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        errors++;
        continue;
      }

      // Hauptzahlen
      final main = parts[1]
          .trim()
          .split(RegExp(r'\s+'))
          .map(int.parse)
          .toList();
      if (main.length != 5) {
        errors++;
        continue;
      }

      // Eurozahlen
      final euro = parts[2]
          .trim()
          .split(RegExp(r'\s+'))
          .map(int.parse)
          .toList();
      if (euro.length != 2) {
        errors++;
        continue;
      }

      valid++;
    } catch (_) {
      errors++;
    }
  }

  return ParserResult(valid: valid, errors: errors);
}
