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
  final LottozahlenOnlineScraper lottoScraper = LottozahlenOnlineScraper("6aus49");
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

    final numbersPart = _convertNumbersToCompact(ziehung.zahlen, ziehung.superzahl);

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
          "SELECT COUNT(*) FROM ziehungen WHERE spieltyp = ? AND strftime('%Y', datum) = ?",
          [spieltyp, year.toString()]
        );
        
        final existingCount = count.first['count'] as int;
        if (existingCount == 0) {
          result.add(year);
        }
      }
    }
    
    else if (spieltyp == "eurojackpot") {
      for (int year = 2012; year <= currentYear; year++) {
        final count = await dbInstance.rawQuery(
          "SELECT COUNT(*) FROM ziehungen WHERE spieltyp = ? AND strftime('%Y', datum) = ?",
          [spieltyp, year.toString()]
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
    print("[UPDATE] 🚀 Starte automatisches Update");
    final results = {
      "lotto": {"imported": 0, "skipped": 0, "errors": 0},
      "eurojackpot": {"imported": 0, "skipped": 0, "errors": 0},
      "total": {"imported": 0, "skipped": 0, "errors": 0}
    };

    try {
      // LOTTO 6AUS49 UPDATE
      print("[UPDATE] 🔍 Prüfe fehlende Lotto-Daten...");
      final missingLottoYears = await _findMissingYears("lotto_6aus49");
      
      if (missingLottoYears.isNotEmpty) {
        print("[UPDATE] 📥 Lade Lotto-Daten für Jahre: $missingLottoYears");
        
        final compactLines = <String>[];
        
        for (final year in missingLottoYears) {
          try {
            print("[UPDATE]   🗓️  Scrape Jahr $year...");
            final ziehungen = await lottoScraper.ladeJahr(year);
            print("[UPDATE]   ✅ $year: ${ziehungen.length} Ziehungen gefunden");
            
            for (final ziehung in ziehungen) {
              final compactLine = _convertLottoToCompact(ziehung);
              compactLines.add(compactLine);
            }
          } catch (e) {
            print("[UPDATE]   ❌ Fehler bei Jahr $year: $e");
            results["lotto"]!["errors"] = (results["lotto"]!["errors"] as int) + 1;
          }
        }
        
        if (compactLines.isNotEmpty) {
          print("[UPDATE] 📊 Importiere ${compactLines.length} Lotto-Zeilen...");
          final importText = compactLines.join("\n");
          final importResult = await db.importLotto6aus49Manually(importText);
          
          results["lotto"]!["imported"] = (importResult["imported"] ?? 0);
          results["lotto"]!["skipped"] = (importResult["skipped"] ?? 0);
          results["lotto"]!["errors"] = (results["lotto"]!["errors"] as int) + (importResult["errors"] ?? 0);
        }
      } else {
        print("[UPDATE] ✅ Alle Lotto-Daten aktuell");
      }

      // EUROJACKPOT UPDATE
      print("[UPDATE] 🔍 Prüfe fehlende Eurojackpot-Daten...");
      final missingEuroYears = await _findMissingYears("eurojackpot");
      
      if (missingEuroYears.isNotEmpty) {
        print("[UPDATE] 📥 Lade Eurojackpot-Daten für Jahre: $missingEuroYears");
        
        final compactLines = <String>[];
        
        for (final year in missingEuroYears) {
          try {
            print("[UPDATE]   🗓️  Scrape Jahr $year...");
            final ziehungen = await euroScraper.ladeJahr(year);
            print("[UPDATE]   ✅ $year: ${ziehungen.length} Ziehungen gefunden");
            
            for (final ziehung in ziehungen) {
              final compactLine = _convertEurojackpotToCompact(ziehung);
              compactLines.add(compactLine);
            }
          } catch (e) {
            print("[UPDATE]   ❌ Fehler bei Jahr $year: $e");
            results["eurojackpot"]!["errors"] = (results["eurojackpot"]!["errors"] as int) + 1;
          }
        }
        
        if (compactLines.isNotEmpty) {
          print("[UPDATE] 📊 Importiere ${compactLines.length} Eurojackpot-Zeilen...");
          final importText = compactLines.join("\n");
          final importResult = await db.importEurojackpotManually(importText);
          
          results["eurojackpot"]!["imported"] = (importResult["imported"] ?? 0);
          results["eurojackpot"]!["skipped"] = (importResult["skipped"] ?? 0);
          results["eurojackpot"]!["errors"] = (results["eurojackpot"]!["errors"] as int) + (importResult["errors"] ?? 0);
        }
      } else {
        print("[UPDATE] ✅ Alle Eurojackpot-Daten aktuell");
      }

      // GESAMTSTATISTIK
      results["total"]!["imported"] = (results["lotto"]!["imported"] as int) + (results["eurojackpot"]!["imported"] as int);
      results["total"]!["skipped"] = (results["lotto"]!["skipped"] as int) + (results["eurojackpot"]!["skipped"] as int);
      results["total"]!["errors"] = (results["lotto"]!["errors"] as int) + (results["eurojackpot"]!["errors"] as int);

      print("[UPDATE] ========================================");
      print("[UPDATE] 📊 UPDATE ABGESCHLOSSEN:");
      print("[UPDATE] Lotto:   ✅ ${results["lotto"]!["imported"]}, ⏭️  ${results["lotto"]!["skipped"]}, ❌ ${results["lotto"]!["errors"]}");
      print("[UPDATE] Eurojackpot: ✅ ${results["eurojackpot"]!["imported"]}, ⏭️  ${results["eurojackpot"]!["skipped"]}, ❌ ${results["eurojackpot"]!["errors"]}");
      print("[UPDATE] Gesamt:  ✅ ${results["total"]!["imported"]}, ⏭️  ${results["total"]!["skipped"]}, ❌ ${results["total"]!["errors"]}");
      print("[UPDATE] ========================================");

    } catch (e) {
      print("[UPDATE] ❌ UPDATE FEHLGESCHLAGEN: $e");
      results["total"]!["errors"] = (results["total"]!["errors"] as int) + 1;
    }

    return results;
  }

  // ============================================================
  // EINFACHER UPDATE-BUTTON SERVICE
  // ============================================================
  Future<Map<String, int>> updateCurrentYear() async {
    print("[UPDATE] 🔄 Update aktuelles Jahr");
    final currentYear = DateTime.now().year;
    final compactLines = <String>[];
    int errors = 0;

    try {
      print("[UPDATE] 📥 Lade Lotto $currentYear...");
      final lottoZiehungen = await lottoScraper.ladeJahr(currentYear);
      for (final ziehung in lottoZiehungen) {
        compactLines.add(_convertLottoToCompact(ziehung));
      }
      print("[UPDATE] ✅ Lotto: ${lottoZiehungen.length} Ziehungen");

      print("[UPDATE] 📥 Lade Eurojackpot $currentYear...");
      final euroZiehungen = await euroScraper.ladeJahr(currentYear);
      for (final ziehung in euroZiehungen) {
        compactLines.add(_convertEurojackpotToCompact(ziehung));
      }
      print("[UPDATE] ✅ Eurojackpot: ${euroZiehungen.length} Ziehungen");

    } catch (e) {
      print("[UPDATE] ❌ Scrape-Fehler: $e");
      errors++;
    }

    if (compactLines.isNotEmpty) {
      final importText = compactLines.join("\n");
      print("[UPDATE] 📊 Importiere ${compactLines.length} Zeilen...");
      
      try {
        final lottoLines = compactLines.where((line) => line.contains("Mo") || 
                                                       line.contains("Di") || 
                                                       line.contains("Mi") || 
                                                       line.contains("Do") || 
                                                       line.contains("Fr") || 
                                                       line.contains("Sa") || 
                                                       line.contains("So")).toList();
        
        final euroLines = compactLines.where((line) => !lottoLines.contains(line)).toList();

        int totalImported = 0;
        
        if (lottoLines.isNotEmpty) {
          final lottoResult = await db.importLotto6aus49Manually(lottoLines.join("\n"));
          totalImported += lottoResult["imported"] ?? 0;
          errors += lottoResult["errors"] ?? 0;
        }
        
        if (euroLines.isNotEmpty) {
          final euroResult = await db.importEurojackpotManually(euroLines.join("\n"));
          totalImported += euroResult["imported"] ?? 0;
          errors += euroResult["errors"] ?? 0;
        }

        return {
          "imported": totalImported,
          "errors": errors,
          "total_lines": compactLines.length
        };

      } catch (e) {
        print("[UPDATE] ❌ Import-Fehler: $e");
        return {"imported": 0, "errors": errors + 1, "total_lines": compactLines.length};
      }
    }

    return {"imported": 0, "errors": errors, "total_lines": 0};
  }
}
