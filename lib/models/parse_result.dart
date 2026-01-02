class ParseResult {
  final int valid;
  final int errors;
  final List<String> preview;

  const ParseResult({
    required this.valid,
    required this.errors,
    required this.preview,
  });
}
