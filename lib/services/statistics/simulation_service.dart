import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class SimulationService {
  final LottoDatabase db = LottoDatabase();

  Future<SimulationSummary> simulate({
    required String spieltyp,
    required List<int> tip,
    int simulations = 10000,
  }) async {
    final database = await db.database;
    final draws = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
      limit: 100, // Nur letzte 100 für Simulation
    );

    // Vereinfachte Simulation
    final matchesHistogram = <int, int>{};
    for (int i = 0; i <= tip.length; i++) {
      matchesHistogram[i] = 0;
    }

    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final drawnNumbers = numbersStr.split(' ').map(int.parse).toSet();
      final tipNumbers = tip.toSet();
      
      final matches = drawnNumbers.intersection(tipNumbers).length;
      matchesHistogram[matches] = matchesHistogram[matches]! + 1;
    }

    final sorted = draws.length > 0 
        ? Map.fromEntries(
            matchesHistogram.entries.toList()..sort((a, b) => b.key.compareTo(a.key))
          )
        : matchesHistogram;

    return SimulationSummary(
      spieltyp: spieltyp,
      draws: draws.length,
      histogram: sorted,
    );
  }
}

// SimulationSummary Modell (falls nicht vorhanden)
class SimulationSummary {
  final String spieltyp;
  final int draws;
  final Map<int, int> histogram;

  SimulationSummary({
    required this.spieltyp,
    required this.draws,
    required this.histogram,
  });
}
