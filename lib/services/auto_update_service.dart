import 'dart:async';
import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'package:lottogenerator_v4/services/lottozahlenonline_scraper.dart';
import 'package:lottogenerator_v4/services/eurojackpot_scraper.dart';
import 'package:lottogenerator_v4/models/lotto_data.dart';

// ============================================================
// AUTOMATISCHER UPDATE-SERVICE
// ============================================================
class AutoUpdateService {
  final LottoDatabase db = LottoDatabase.instance;
  final LottozahlenOnlineScraper lottoScraper =
      LottozahlenOnlineScraper("6aus49");
  final EurojackpotScraper euroScraper = EurojackpotScraper();

  // ============================================================
  // KONVERTIERUNG: LottoZiehung → Kompakt-Format
  // ============================================================
  String _convertLottoToCompact(LottoZiehung ziehung) {
    final wochentagIndex = ziehung.datum.weekday;
    final wochentagCodes = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
    final wochentag = wochentagCodes[wochentagIndex - 1];

    final dayStr = ziehung.datum.day.toString().padLeft(2, '0');
    final monthStr = ziehung.datum.month.toString().padLeft(2, '0');
    final yearStr = ziehung.datum.year.toString();

    final numbersPart =
        _convertNumbersToCompact(ziehung.zahlen, ziehung.superzahl);

    return "1$dayStr.$monthStr.$yearStr$wochentag$numbersPart";
  }

  String _convertEurojackpotToCompact(LottoZiehung ziehung) {
    final dayStr = ziehung.datum.day.toString().padLeft(2, '0');
    final monthStr = ziehung.datum.month.toString().padLeft(2, '0');
    final yearStr = ziehung.datum.year.toString();

    final numbersPart = _convertNumbersToCompact(ziehung.zahlen, 0);

    return "1$dayStr.$monthStr.$yearStr$numbersPart";
  }

  String _convertNumbersToCompact(List<int> zahlen, int superzahl) {
    final sorted = List<int>.from(zahlen)..sort();

    String result = "";
    for (int i = sorted.length - 1; i >= 0; i--) {
      result += sorted[i].toString().padLeft(2, '0');
    }

    if (superzahl > 0) {
      result += superzahl.toString();
    }
    return result;
  }

  // ============================================================
  // DATENBANK-ABFRAGE: Fehlende Jahre finden
  // ============================================================
  Future<List<int>> _findMissingYears(String spieltyp) async {
    final dbInstance = await db.database;
    final result = <int>{};

    final currentYear = DateTime.now().year;
    result.add(currentYear);
    result.add(currentYear - 1);

    if (spieltyp == "lotto_6aus49") {
      for (int year = 1955; year <= currentYear; year++) {
        final count = await dbInstance.rawQuery(
          "SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = ? AND strftime('%Y', datum) = ?",
          [spieltyp, year.toString()],
        );
        final existingCount = count.first['count'] as int;
        if (existingCount == 0) {
          result.add(year);
        }
      }
    } else if (spieltyp == "eurojackpot") {
      for (int year = 2012; year <= currentYear; year++) {
        final count = await dbInstance.rawQuery(
          "SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = ? AND strftime('%Y', datum) = ?",
          [spieltyp, year.toString()],
        );
        final existingCount = count.first['count'] as int;
        if (existingCount == 0) {
          result.add(year);
        }
      }
    }

    return result.toList()..sort();
  }

  // ============================================================
  // HAUPTPROZESS: Automatisches Update
  // ============================================================
  Future<Map<String, dynamic>> performAutoUpdate() async {
    final results = {
      "lotto": {"imported": 0, "skipped": 0, "errors": 0},
      "eurojackpot": {"imported": 0, "skipped": 0, "errors": 0},
      "total": {"imported": 0, "skipped": 0, "errors": 0},
    };

    try {
      // LOTTO 6aus49
      final missingLottoYears = await _findMissingYears("lotto_6aus49");
      if (missingLottoYears.isNotEmpty) {
        final compactLines = <String>[];

        for (final year in missingLottoYears) {
          final ziehungen = await lottoScraper.ladeJahr(year);
          for (final ziehung in ziehungen) {
            compactLines.add(_convertLottoToCompact(ziehung));
          }
        }

        if (compactLines.isNotEmpty) {
          final importText = compactLines.join("\n");
          final importResult =
              await db.importLotto6aus49Manually(importText);

          results["lotto"]!["imported"] = importResult["imported"] ?? 0;
          results["lotto"]!["skipped"] = importResult["skipped"] ?? 0;
          results["lotto"]!["errors"] =
              (results["lotto"]!["errors"] as int) +
              (importResult["errors"] ?? 0);
        }
      }

      // EUROJACKPOT
      final missingEuroYears = await _findMissingYears("eurojackpot");
      if (missingEuroYears.isNotEmpty) {
        final compactLines = <String>[];

        for (final year in missingEuroYears) {
          final ziehungen = await euroScraper.ladeJahr(year);
          for (final ziehung in ziehungen) {
            compactLines.add(_convertEurojackpotToCompact(ziehung));
          }
        }

        if (compactLines.isNotEmpty) {
          final importText = compactLines.join("\n");
          final importResult =
              await db.importEurojackpotManually(importText);

          results["eurojackpot"]!["imported"] =
              importResult["imported"] ?? 0;
          results["eurojackpot"]!["skipped"] =
              importResult["skipped"] ?? 0;
          results["eurojackpot"]!["errors"] =
              (results["eurojackpot"]!["errors"] as int) +
              (importResult["errors"] ?? 0);
        }
      }

      results["total"]!["imported"] =
          (results["lotto"]!["imported"] as int) +
          (results["eurojackpot"]!["imported"] as int);
      results["total"]!["skipped"] =
          (results["lotto"]!["skipped"] as int) +
          (results["eurojackpot"]!["skipped"] as int);
      results["total"]!["errors"] =
          (results["lotto"]!["errors"] as int) +
          (results["eurojackpot"]!["errors"] as int);
    } catch (e) {
      results["total"]!["errors"] =
          (results["total"]!["errors"] as int) + 1;
    }

    return results;
  }

  // ============================================================
  // UPDATE AKTUELLES JAHR
  // ============================================================
  Future<Map<String, int>> updateCurrentYear() async {
    final currentYear = DateTime.now().year;
    final compactLines = <String>[];
    int errors = 0;

    try {
      final lottoZiehungen = await lottoScraper.ladeJahr(currentYear);
      for (final ziehung in lottoZiehungen) {
        compactLines.add(_convertLottoToCompact(ziehung));
      }

      final euroZiehungen = await euroScraper.ladeJahr(currentYear);
      for (final ziehung in euroZiehungen) {
        compactLines.add(_convertEurojackpotToCompact(ziehung));
      }
    } catch (_) {
      errors++;
    }

    if (compactLines.isNotEmpty) {
      final importText = compactLines.join("\n");

      int imported = 0;

      try {
        final lottoResult =
            await db.importLotto6aus49Manually(importText);
        imported += lottoResult["imported"] ?? 0;
        errors += lottoResult["errors"] ?? 0;
      } catch (_) {}

      try {
        final euroResult =
            await db.importEurojackpotManually(importText);
        imported += euroResult["imported"] ?? 0;
        errors += euroResult["errors"] ?? 0;
      } catch (_) {}

      return {
        "imported": imported,
        "errors": errors,
        "total_lines": compactLines.length,
      };
    }

    return {"imported": 0, "errors": errors, "total_lines": 0};
  }
}
