import 'package:lottogenerator_v4/services/lotto_database.dart';

class SumService {
  final LottoDatabase db = LottoDatabase();

  Future<SumStats> sumStats({required String spieltyp}) async {
    final database = await db.database;
    final draws = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
    );

    if (draws.isEmpty) {
      return SumStats(
        spieltyp: spieltyp,
        draws: 0,
        minSum: 0,
        maxSum: 0,
        avgSum: 0,
        histogram: {},
      );
    }

    int minSum = 999;
    int maxSum = 0;
    int totalSum = 0;
    final histogram = <int, int>{};

    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      final sum = numbers.reduce((a, b) => a + b);
      
      if (sum < minSum) minSum = sum;
      if (sum > maxSum) maxSum = sum;
      totalSum += sum;
      histogram[sum] = (histogram[sum] ?? 0) + 1;
    }

    return SumStats(
      spieltyp: spieltyp,
      draws: draws.length,
      minSum: minSum,
      maxSum: maxSum,
      avgSum: totalSum / draws.length,
      histogram: histogram,
    );
  }
}
