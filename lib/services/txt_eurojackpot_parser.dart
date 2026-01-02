import '../models/parse_result.dart';

ParseResult parseEurojackpotTxt(String input) {
  final lines = input.split('\n');
  final preview = <String>[];
  int valid = 0;
  int errors = 0;

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    // Format: YYYY-MM-DD | 5 Zahlen | 2 Eurozahlen
    final parts = line.split('|');
    if (parts.length != 3) {
      errors++;
      continue;
    }

    final main =
        parts[1].trim().split(' ').where((e) => e.isNotEmpty).toList();
    final euro =
        parts[2].trim().split(' ').where((e) => e.isNotEmpty).toList();

    if (main.length != 5 || euro.length != 2) {
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
