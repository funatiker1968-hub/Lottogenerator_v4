import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

/// Offizielle JSON-API für historische Lottozahlen
///
/// Beispiel:
///   https://www.lottozahlenonline-api.de/api/6aus49/2024.json
///
/// Unterstützte Spieltypen:
///  - 6aus49
///  - eurojackpot
///
/// Diese Klasse importiert echte historische Ziehungen automatisch
/// und speichert sie in ErweiterteLottoDatenbank.

class LottoApiImporter {
  final String baseUrl = "https://www.lottozahlenonline-api.de/api";

  /// Importiert einen Jahresbereich (z. B. 2010–2024)
  Future<ImporterResult> importJahresBereich({
    required String spieltyp,
    required int startJahr,
    required int endJahr,
  }) async {
    final result = ImporterResult();

    if (startJahr > endJahr) {
      result.success = false;
      result.message = "Startjahr muss kleiner als Endjahr sein.";
      return result;
    }

    int gesamtImportiert = 0;
    List<String> fehler = [];

    for (int jahr = startJahr; jahr <= endJahr; jahr++) {
      final r = await importJahr(spieltyp: spieltyp, jahr: jahr);

      if (r.success) {
        gesamtImportiert += r.importedCount;
      } else {
        fehler.add("Jahr $jahr: ${r.message}");
      }

      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (gesamtImportiert == 0) {
      result.success = false;
      result.message = "Keine Ziehungen importiert.\n${fehler.join("\n")}";
    } else {
      result.success = true;
      result.importedCount = gesamtImportiert;
      result.message =
          "Erfolgreich $gesamtImportiert Ziehungen importiert.\n${fehler.isEmpty ? "" : "Teilweise Fehler:\n${fehler.join("\n")}"}";
    }

    return result;
  }

  /// Importiert ein einzelnes Jahr
  Future<ImporterResult> importJahr({
    required String spieltyp,
    required int jahr,
  }) async {
    final result = ImporterResult();
    final url = Uri.parse("$baseUrl/$spieltyp/$jahr.json");

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        result.success = false;
        result.message = "Server antwortete mit Status ${response.statusCode}";
        return result;
      }

      final data = jsonDecode(response.body);

      if (data is! List) {
        result.success = false;
        result.message = "Unerwartetes Datenformat";
        return result;
      }

      int counter = 0;

      for (final entry in data) {
        if (entry is! Map) continue;

        final datumString = entry["datum"];
        final zahlen = (entry["zahlen"] as List).cast<int>();
        final superzahl = entry["superzahl"] ?? 0;

        final datum = DateTime.tryParse(datumString);
        if (datum == null) continue;

        final ziehung = LottoZiehung(
          datum: datum,
          zahlen: zahlen,
          superzahl: superzahl,
          spieltyp: spieltyp,
        );

        await ErweiterteLottoDatenbank.fuegeZiehungHinzu(ziehung);
        counter++;
      }

      result.success = true;
      result.importedCount = counter;
      result.message = "$counter Ziehungen importiert";

    } catch (e) {
      result.success = false;
      result.message = "Fehler: $e";
    }

    return result;
  }
}

class ImporterResult {
  bool success = false;
  int importedCount = 0;
  String message = "";

  @override
  String toString() =>
      success ? "✅ $message" : "❌ $message";
}
