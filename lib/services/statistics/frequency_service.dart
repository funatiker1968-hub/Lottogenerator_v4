import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class FrequencyService {
  final LottoDatabase db = LottoDatabase();

  Future<FrequencyResult> frequency({
    required String spieltyp,
    int lastNDraws = 0,
    bool superzahl = false,
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
    final counts = <int, int>{};
    int numbersPerDraw = 0;
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      
      final numbersToCount = takeNumbersPerDraw > 0 && numbers.length > euroOffset
          ? numbers.sublist(euroOffset, euroOffset + takeNumbersPerDraw)
          : numbers;
      
      numbersPerDraw = numbersToCount.length;
      
      for (final num in numbersToCount) {
        counts[num] = (counts[num] ?? 0) + 1;
      }
    }
    
    return FrequencyResult(
      spieltyp: spieltyp,
      counts: counts,
      totalDraws: draws.length,
      numbersPerDraw: numbersPerDraw,
    );
  }
}
