import '../models/parse_result.dart';

ParseResult parseLottoTxt(String input) {
  final lines = input.split('\n');
  final preview = <String>[];
  int valid = 0;
  int errors = 0;

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    // Format: DD.MM.YYYY | 6 Zahlen | Superzahl
    final parts = line.split('|');
    if (parts.length != 3) {
      errors++;
      continue;
    }

    final numbers =
        parts[1].trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (numbers.length != 6) {
      errors++;
      continue;
    }

    valid++;
    if (preview.length < 5) {
      preview.add(line);
    }
  }

  return ParseResult(
    valid: valid,
    errors: errors,
    preview: preview,
  );
}
