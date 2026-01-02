import '../models/parse_result.dart';

ParseResult parseEurojackpotTxt(String text) {
  int valid = 0;
  int errors = 0;
  final errorLines = <String>[];

  final lines = text.split('\n');

  for (final line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;

    final parts = line.split('|');
    if (parts.length < 3) {
      errors++;
      errorLines.add(line);
      continue;
    }

    valid++;
  }

  return ParseResult(
    valid: valid,
    errors: errors,
    errorLines: errorLines,
  );
}
