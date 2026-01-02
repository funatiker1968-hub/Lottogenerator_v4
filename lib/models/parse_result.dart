class ParseResult {
  final List<Map<String, dynamic>> entries;
  final int valid;
  final int errors;

  const ParseResult({
    required this.entries,
    required this.valid,
    required this.errors,
  });
}
