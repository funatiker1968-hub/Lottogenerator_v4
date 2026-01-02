import '../models/parse_result.dart';

ParseResult parseEurojackpotTxt(String text) {
  final lines = text.split('\n');
  final entries = <Map<String, dynamic>>[];
  int errors = 0;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    try {
      // Format:
      // YYYY-MM-DD | 01 02 03 04 05 | 1 2
      final parts = trimmed.split('|');
      if (parts.length != 3) throw 'Ungültige Zeile';

      final date = parts[0].trim();
      final main =
          parts[1].trim().split(' ').map(int.parse).toList();
      final euro =
          parts[2].trim().split(' ').map(int.parse).toList();

      entries.add({
        'date': date,
        'numbers': main,
        'euro': euro,
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
