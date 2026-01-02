import '../models/parse_result.dart';

ParseResult parseLottoTxt(String text) {
  final lines = text.split('\n');
  final entries = <Map<String, dynamic>>[];
  int errors = 0;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    try {
      // Format:
      // DD.MM.YYYY | 1 2 3 4 5 6 | -1
      final parts = trimmed.split('|');
      if (parts.length < 2) throw 'Ungültige Zeile';

      final date = parts[0].trim();
      final numbers =
          parts[1].trim().split(' ').map(int.parse).toList();
      final superzahl =
          parts.length >= 3 ? int.parse(parts[2].trim()) : -1;

      entries.add({
        'date': date,
        'numbers': numbers,
        'superzahl': superzahl,
      });
    } catch (_) {
      errors++;
    }
  }

  return ParseResult(
    entries: entries,
    valid: entries.length,
    errors: errors,
  );
}
