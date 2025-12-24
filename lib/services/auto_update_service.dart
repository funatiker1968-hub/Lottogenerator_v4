import 'lotto_database.dart';

// ============================================================
// AUTOMATISCHER UPDATE-SERVICE (TEMPORÄR VEREINFACHT)
// ============================================================
class AutoUpdateService {
  final LottoDatabase db = LottoDatabase();

  // ============================================================
  // UPDATE FÜR DAS AKTUELLE JAHR (DEMO-IMPLEMENTIERUNG)
  // ============================================================
  Future<Map<String, dynamic>> updateCurrentYear() async {
    // TEMPORÄR: Gibt Demo-Daten zurück bis Scraper implementiert sind
    return {
      'imported': 0,
      'errors': 0,
      'total_lines': 0,
      'message': 'AutoUpdate temporär deaktiviert. Scraper müssen implementiert werden.'
    };
  }

  // ============================================================
  // UPDATE FÜR SPEZIFISCHES JAHR
  // ============================================================
  Future<Map<String, dynamic>> updateYear(String year) async {
    return {
      'imported': 0,
      'errors': 0,
      'total_lines': 0,
      'message': 'Scraper-Funktionalität muss noch implementiert werden.'
    };
  }

  // ============================================================
  // DEMO-DATEN GENERIEREN (FÜR TESTZWECKE)
  // ============================================================
  Future<void> generateDemoData() async {
    final demoLottoLines = [
      '101.01.2025Mi37151826332',
      '102.01.2025Do4152930382',
      '103.01.2025Fr1227323645'
    ];

    final demoEuroLines = [
      '101.03.2025120212729810',
      '102.03.202515273032116',
      '103.03.202518293142105'
    ];

    for (final line in demoLottoLines) {
      try {
        await db.importLotto6aus49Manually(line);
      } catch (e) {
        // Ignoriere Fehler in Demo
      }
    }

    for (final line in demoEuroLines) {
      try {
        await db.importEurojackpotManually(line);
      } catch (e) {
        // Ignoriere Fehler in Demo
      }
    }
  }
}
