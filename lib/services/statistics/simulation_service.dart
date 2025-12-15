import '../../models/lotto_data.dart';
import '../lotto_database_erweitert.dart';
import 'statistics_models.dart';

class SimulationService {
  /// Lotto 6aus49:
  /// tipMain = 6 Zahlen
  /// tipExtra = Superzahl (0..9) optional (null = ignorieren)
  Future<SimulationSummary> simulateLotto6aus49({
    required List<int> tipMain,
    int? superzahl,
  }) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp: '6aus49');
    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));

    final tipSet = tipMain.toSet();
    final hist = <String, int>{};

    for (final z in sorted) {
      final hitsMain = z.zahlen.where(tipSet.contains).length;
      final hitsSz = (superzahl == null) ? 0 : ((z.superzahl == superzahl) ? 1 : 0);

      final key = superzahl == null
          ? '$hitsMain'
          : (hitsSz == 1 ? '$hitsMain+SZ' : '$hitsMain');

      hist[key] = (hist[key] ?? 0) + 1;
    }

    return SimulationSummary(spieltyp: '6aus49', draws: sorted.length, histogram: hist);
  }

  /// Eurojackpot:
  /// tipMain=5 (1..50), tipEuro=2 (1..12)
  Future<SimulationSummary> simulateEurojackpot({
    required List<int> tipMain,
    required List<int> tipEuro,
  }) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp: 'eurojackpot');
    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));

    final mainSet = tipMain.toSet();
    final euroSet = tipEuro.toSet();

    final hist = <String, int>{};

    for (final z in sorted) {
      if (z.zahlen.length < 7) continue;
      final drawMain = z.zahlen.sublist(0, 5);
      final drawEuro = z.zahlen.sublist(5, 7);

      final hitsMain = drawMain.where(mainSet.contains).length;
      final hitsEuro = drawEuro.where(euroSet.contains).length;

      final key = '$hitsMain+$hitsEuro';
      hist[key] = (hist[key] ?? 0) + 1;
    }

    return SimulationSummary(spieltyp: 'eurojackpot', draws: sorted.length, histogram: hist);
  }
}
