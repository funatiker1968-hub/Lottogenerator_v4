import 'package:lottogenerator_v4/services/lotto_database.dart';

class ClusterService {
  final LottoDatabase db = LottoDatabase();

  Future<RangeDistribution> distribution({
    required String spieltyp,
    required List<RangeBucket> buckets,
  }) async {
    final database = await db.database;
    final draws = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
    );

    // Vereinfachte Implementierung für Build
    final counts = <String, int>{};
    for (final bucket in buckets) {
      counts[bucket.label] = 0;
    }

    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      
      for (final num in numbers) {
        for (final bucket in buckets) {
          if (num >= bucket.from && num <= bucket.to) {
            counts[bucket.label] = counts[bucket.label]! + 1;
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
