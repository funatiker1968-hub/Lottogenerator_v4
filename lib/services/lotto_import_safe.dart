import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

/// Kapselt das sichere Speichern von Ziehungen:
/// - nutzt ErweiterteLottoDatenbank.fuegeZiehungWennNeu
/// - verhindert doppelte Einträge (Datum + Spieltyp)
class LottoImportSafe {
  /// Nimmt eine Liste von Ziehungen und speichert nur neue.
  static Future<void> fuegeZiehungenEin(List<LottoZiehung> ziehungen) async {
    for (final z in ziehungen) {
      await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(z);
    }
  }
}
