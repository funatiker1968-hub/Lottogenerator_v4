import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class ClusterService {
  final LottoDatabase db = LottoDatabase();

  Future<RangeDistribution> distribution({
    required String spieltyp,
    required List<RangeBucket> buckets,
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
    final counts = <String, int>{};
    
    // Initialize all buckets with 0
    for (final bucket in buckets) {
      counts[bucket.label] = 0;
    }
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      
      final numbersToCount = takeNumbersPerDraw > 0 && numbers.length > euroOffset
          ? numbers.sublist(euroOffset, euroOffset + takeNumbersPerDraw)
          : numbers;
      
      for (final num in numbersToCount) {
        for (final bucket in buckets) {
          if (bucket.contains(num)) {
            counts[bucket.label] = (counts[bucket.label] ?? 0) + 1;
            break;
          }
        }
      }
    }
    
    return RangeDistribution(
      spieltyp: spieltyp,
      buckets: buckets,
      counts: counts,
    );
  }
}
