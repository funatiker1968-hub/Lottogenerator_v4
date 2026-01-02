class ParseResult {
  final int valid;
  final int errors;
  final List<String> errorLines;

  const ParseResult({
    required this.valid,
    required this.errors,
    this.errorLines = const [],
  });
}
