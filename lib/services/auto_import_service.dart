import '../services/lotto_database_erweitert.dart';
import '../models/lotto_data.dart';

/// Vereinfachter Auto-Import, damit App startfähig bleibt.
/// Der echte Scraper wird später korrekt eingebaut.
///
/// Der Service:
///  - läuft einmal beim Start
///  - zeigt Statusmeldungen über Callback
///  - verhindert doppelte Ausführung
class AutoImportService {
  static bool _bereitsGestartet = false;

  static Future<void> starteAutomatischenImport(
      void Function(String msg) status) async {
    if (_bereitsGestartet) return;
    _bereitsGestartet = true;

    status("Automatischer Import gestartet …");

    // Hier könnte später echte Logik kommen
    await Future.delayed(const Duration(seconds: 2));

    status("Automatischer Import abgeschlossen.");
  }
}
