import 'lotto_database.dart';
import 'lottozahlenonline_scraper.dart';
import 'eurojackpot_scraper.dart';

// ============================================================
// AUTOMATISCHER UPDATE-SERVICE
// ============================================================
class AutoUpdateService {
  final LottoDatabase db = LottoDatabase();
  final LottozahlenOnlineScraper lottoScraper = LottozahlenOnlineScraper("6aus49");
  final EurojackpotScraper euroScraper = EurojackpotScraper();

  // ============================================================
  // UPDATE FÜR DAS AKTUELLE JAHR
  // ============================================================
  Future<Map<String, dynamic>> updateCurrentYear() async {
    final currentYear = DateTime.now().year;
    final results = {
      'imported': 0,
      'errors': 0,
      'total_lines': 0
    };

    try {
      // Lotto 6aus49 Scrapen - vorübergehend deaktiviert bis Scraper fix
      // final lottoData = await lottoScraper.scrapeYear(currentYear.toString());
      // results['total_lines'] = lottoData.length;
      
      // for (final line in lottoData) {
      //   try {
      //     await db.importLotto6aus49Line(line);
      //     results['imported'] = (results['imported'] as int) + 1;
      //   } catch (e) {
      //     results['errors'] = (results['errors'] as int) + 1;
      //   }
      // }

      // Eurojackpot Scrapen - vorübergehend deaktiviert
      // final euroData = await euroScraper.scrapeYear(currentYear.toString());
      // results['total_lines'] = (results['total_lines'] as int) + euroData.length;
      
      // for (final line in euroData) {
      //   try {
      //     await db.importEurojackpotLine(line);
      //     results['imported'] = (results['imported'] as int) + 1;
      //   } catch (e) {
      //     results['errors'] = (results['errors'] as int) + 1;
      //   }
      // }

      // Demo-Daten für Test
      await _addDemoData(results);

    } catch (e) {
      results['errors'] = (results['errors'] as int) + 1;
    }

    return results;
  }

  // ============================================================
  // DEMO-DATEN HINZUFÜGEN (vorübergehend)
  // ============================================================
  Future<void> _addDemoData(Map<String, dynamic> results) async {
    final demoLottoLines = [
      '101.01.2025Mi37151826332',
      '102.01.2025Do4152930382',
      '103.01.2025Fr1227323645'
    ];

    for (final line in demoLottoLines) {
      try {
        await db.importLotto6aus49Line(line);
        results['imported'] = (results['imported'] as int) + 1;
        results['total_lines'] = (results['total_lines'] as int) + 1;
      } catch (e) {
        results['errors'] = (results['errors'] as int) + 1;
      }
    }
  }

  // ============================================================
  // UPDATE FÜR SPEZIFISCHES JAHR
  // ============================================================
  Future<Map<String, dynamic>> updateYear(String year) async {
    final results = {
      'imported': 0,
      'errors': 0,
      'total_lines': 0
    };

    try {
      // Vorübergehend deaktiviert
      // final lottoData = await lottoScraper.scrapeYear(year);
      // results['total_lines'] = lottoData.length;

      // for (final line in lottoData) {
      //   try {
      //     await db.importLotto6aus49Line(line);
      //     results['imported'] = (results['imported'] as int) + 1;
      //   } catch (e) {
      //     results['errors'] = (results['errors'] as int) + 1;
      //   }
      // }

      await _addDemoData(results);

    } catch (e) {
      results['errors'] = (results['errors'] as int) + 1;
    }

    return results;
  }

  // ============================================================
  // TEST-METHODE: DEMO-DATEN GENERIEREN
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
        await db.importLotto6aus49Line(line);
      } catch (e) {
        // Ignoriere Fehler in Demo
      }
    }

    for (final line in demoEuroLines) {
      try {
        await db.importEurojackpotLine(line);
      } catch (e) {
        // Ignoriere Fehler in Demo
      }
    }
  }
}
