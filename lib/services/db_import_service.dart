import '../models/parse_result.dart';

enum ImportSystem { lotto, eurojackpot }

class DbImportService {
  /// Zentrale Import-Methode (DB-frei)
  static ImportSummary importFromParseResult(
    ParseResult result, {
    required ImportSystem system,
  }) {
    return ImportSummary(
      system: system,
      total: result.entries.length,
      imported: result.entries.length,
      skipped: 0,
      errors: result.errors,
    );
  }
}

/// Rückgabeobjekt für UI / Logging
class ImportSummary {
  final ImportSystem system;
  final int total;
  final int imported;
  final int skipped;
  final int errors;

  const ImportSummary({
    required this.system,
    required this.total,
    required this.imported,
    required this.skipped,
    required this.errors,
  });
}
