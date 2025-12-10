import '../services/lotto_database_erweitert.dart' as erweiterteDB;
import '../models/lotto_data.dart';

class MultiLottoImporter {
  /// Import mit Fortschritt-Callback
  Future<void> importiereJahresBereich(
    int startJahr,
    int endJahr,
    void Function(String status) onProgress,
  ) async {
    for (int jahr = startJahr; jahr <= endJahr; jahr++) {
      onProgress("Importiere Jahr $jahr ...");

      // Hier später echte Import-Logik einsetzen
      await Future.delayed(const Duration(milliseconds: 400));

      // Platzhalter für echte Datenbank-Schritte:
      // await erweiterteDB.ErweiterteLottoDatenbank.fuegeZiehungHinzu(...);
    }

    onProgress("Import abgeschlossen.");
  }
}
