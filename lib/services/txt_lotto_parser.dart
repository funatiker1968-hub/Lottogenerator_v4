import '../models/parse_result.dart';

ParseResult parseLottoTxt(String text) {
  int valid = 0;
  int errors = 0;
  final errorLines = <String>[];

  final lines = text.split('\n');

  for (final line in lines) {
    if (line.trim().isEmpty) continue;

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
