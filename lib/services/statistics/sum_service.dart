import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class SumService {
  final LottoDatabase db = LottoDatabase();

  Future<SumStats> sumStats({
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
    
    if (draws.isEmpty) {
      return SumStats(
        spieltyp: spieltyp,
        countDraws: 0,
        minSum: 0,
        maxSum: 0,
        avgSum: 0.0, // Korrektur: 0.0 statt 0
      );
    }
    
    int minSum = 999;
    int maxSum = 0;
    int totalSum = 0;
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      
      final numbersToSum = takeNumbersPerDraw > 0 && numbers.length > euroOffset
          ? numbers.sublist(euroOffset, euroOffset + takeNumbersPerDraw)
          : numbers;
      
      final sum = numbersToSum.fold(0, (a, b) => a + b);
      
      if (sum < minSum) minSum = sum;
      if (sum > maxSum) maxSum = sum;
      totalSum += sum;
    }
    
    final avgSum = draws.isNotEmpty ? totalSum / draws.length : 0.0;
    
    return SumStats(
      spieltyp: spieltyp,
      countDraws: draws.length,
      minSum: minSum,
      maxSum: maxSum,
      avgSum: avgSum,
    );
  }
}
