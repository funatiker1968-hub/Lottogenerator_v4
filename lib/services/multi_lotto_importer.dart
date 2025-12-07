// ============================================================================
// MULTI-SOURCE LOTTO IMPORTER
// Unterstützt CSV, JSON, HTML, manuelle Texteingabe
// ============================================================================

// BLOCK 1: IMPORTS
// ============================================================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lotto_data.dart';
import 'lotto_database.dart';

// ============================================================================
// BLOCK 2: DATENQUELLEN – ENUM
// ============================================================================
enum LottoQuelle {
  sachsenlottoCSV,
  githubJSON,
  lottoDE_HTML,
  lottoOnline_HTML,
  manuellerText,
}

// ============================================================================
// BLOCK 3: Ergebnisobjekt
// ============================================================================
class MultiImportResult {
  bool success = false;
  int importedCount = 0;
  String message = '';
  String errorMessage = '';

  @override
  String toString() {
    if (success) return "✅ $message";
    return "❌ $errorMessage";
  }
}

// ============================================================================
// BLOCK 4: Multi-Source Lotto Importer
// ============================================================================
class MultiLottoImporter {
  // ========================================================================
  // HAUPTFUNKTION – entscheidet automatisch über die beste Datenquelle
  // ========================================================================
  Future<MultiImportResult> importiereHistorie({
    required int startJahr,
    required int endJahr,
    required String spieltyp,
    String? manuellerText,
  }) async {
    final result = MultiImportResult();

    if (startJahr > endJahr) {
      result.errorMessage = "Startjahr > Endjahr.";
      return result;
    }

    // REIHENFOLGE:
    // 1. CSV
    final csv = await _importFromSachsenlottoCSV(startJahr, endJahr, spieltyp);
    if (csv.success) return csv;

    // 2. JSON von GitHub
    final json = await _importFromGithubJSON(startJahr, endJahr, spieltyp);
    if (json.success) return json;

    // 3. lotto.de HTML Scraper
    final html1 = await _importFromLottoDE_HTML(startJahr, endJahr, spieltyp);
    if (html1.success) return html1;

    // 4. lottozahlenonline.de
    final html2 =
        await _importFromLottoOnlineHTML(startJahr, endJahr, spieltyp);
    if (html2.success) return html2;

    // 5. manueller Text (Fallback)
    if (manuellerText != null) {
      final txt = await _importFromText(manuellerText, spieltyp);
      return txt;
    }

    // Keine Quelle erfolgreich
    result.errorMessage = "Keine Datenquelle lieferte Ergebnisse.";
    return result;
  }

  // ========================================================================
  // QUELLE 1: Sachsenlotto CSV
  // ========================================================================
  Future<MultiImportResult> _importFromSachsenlottoCSV(
      int startJahr, int endJahr, String spieltyp) async {
    final r = MultiImportResult();

    try {
      final url = "https://www.sachsenlotto.de/.../DownloadArchiv.csv"; // Beispiel

      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode != 200) {
        r.errorMessage = "CSV nicht erreichbar.";
        return r;
      }

      final lines = const LineSplitter().convert(resp.body);
      int count = 0;

      for (final line in lines) {
        final s = line.split(";");
        if (s.length < 7) continue;

        final numbers = s
            .sublist(1, 7)
            .map((v) => int.tryParse(v) ?? 0)
            .where((n) => n >= 1 && n <= 49)
            .toList();

        if (numbers.length != 6) continue;

        count++;

        final ziehung = LottoZiehung(
          datum: DateTime.tryParse(s[0]) ?? DateTime.now(),
          zahlen: numbers,
          superzahl: 0,
          spieltyp: spieltyp,
        );

        await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
      }

      r.success = true;
      r.importedCount = count;
      r.message = "CSV erfolgreich: $count Ziehungen importiert.";
      return r;
    } catch (e) {
      r.errorMessage = "Fehler CSV: $e";
      return r;
    }
  }

  // ========================================================================
  // QUELLE 2: GitHub JSON Archiv
  // ========================================================================
  Future<MultiImportResult> _importFromGithubJSON(
      int startJahr, int endJahr, String spieltyp) async {
    final r = MultiImportResult();

    try {
      final url = "https://raw.githubusercontent.com/.../lotto_6aus49.json";

      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        r.errorMessage = "GitHub JSON nicht erreichbar.";
        return r;
      }

      final list = json.decode(resp.body) as List<dynamic>;
      int count = 0;

      for (final entry in list) {
        final jahr = entry["year"];
        if (jahr < startJahr || jahr > endJahr) continue;

        final ziehung = LottoZiehung(
          datum: DateTime.parse(entry["date"]),
          zahlen: List<int>.from(entry["zahlen"]),
          superzahl: entry["superzahl"],
          spieltyp: spieltyp,
        );

        await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
        count++;
      }

      r.success = true;
      r.importedCount = count;
      r.message = "GitHub JSON: $count Ziehungen importiert.";
      return r;
    } catch (e) {
      r.errorMessage = "Fehler JSON: $e";
      return r;
    }
  }

  // ========================================================================
  // QUELLE 3: lotto.de HTML
  // ========================================================================
  Future<MultiImportResult> _importFromLottoDE_HTML(
      int start, int end, String spieltyp) async {
    final r = MultiImportResult();
    r.errorMessage = "lotto.de HTML noch nicht implementiert.";
    return r;
  }

  // ========================================================================
  // QUELLE 4: lottozahlenonline.de HTML
  // ========================================================================
  Future<MultiImportResult> _importFromLottoOnlineHTML(
      int start, int end, String spieltyp) async {
    final r = MultiImportResult();
    r.errorMessage = "lottozahlenonline.de wegen JavaScript nicht automatisch möglich.";
    return r;
  }

  // ========================================================================
  // QUELLE 5: Manueller Text
  // ========================================================================
  Future<MultiImportResult> _importFromText(
      String rawText, String spieltyp) async {
    final r = MultiImportResult();
    int count = 0;

    final lines = rawText.split("\n");

    for (final l in lines) {
      final nums = RegExp(r"\b\d{1,2}\b")
          .allMatches(l)
          .map((m) => int.parse(m.group(0)!))
          .where((n) => n >= 1 && n <= 49)
          .toList();

      if (nums.length < 6) continue;
      count++;

      final ziehung = LottoZiehung(
        datum: DateTime.now().subtract(Duration(days: count * 7)),
        zahlen: nums.take(6).toList(),
        superzahl: 0,
        spieltyp: spieltyp,
      );

      await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
    }

    r.success = true;
    r.importedCount = count;
    r.message = "Manueller Import: $count Ziehungen hinzugefügt.";
    return r;
  }
}
