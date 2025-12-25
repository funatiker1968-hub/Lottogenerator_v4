import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class PairService {
  final LottoDatabase db = LottoDatabase();

  Future<PairResult> pairs({
    required String spieltyp,
    int lastNDraws = 0,
    int takeNumbersPerDraw = 6,
    int euroOffset = 0,
  }) async {
    final database = await db.database;
    
    String query = "SELECT * FROM ziehungen WHERE spieltyp = ?";
    final args = [spieltyp];
    
    if (lastNDraws > 0) {
      query += " ORDER BY datum DESC LIMIT ?";
      args.add(lastNDraws.toString());
    }
    
    final draws = await database.rawQuery(query, args);
    final counts = <PairKey, int>{};
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      
      final numbersToCount = takeNumbersPerDraw > 0 && numbers.length > euroOffset
          ? numbers.sublist(euroOffset, euroOffset + takeNumbersPerDraw)
          : numbers;
      
      // Sort numbers to ensure consistent pair ordering
      numbersToCount.sort();
      
      // Count all pairs
      for (int i = 0; i < numbersToCount.length; i++) {
        for (int j = i + 1; j < numbersToCount.length; j++) {
          final pair = PairKey(numbersToCount[i], numbersToCount[j]);
          counts[pair] = (counts[pair] ?? 0) + 1;
        }
      }
    }
    
    return PairResult(
      spieltyp: spieltyp,
      counts: counts,
    );
  }
}
