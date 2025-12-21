import '../../models/lotto_data.dart';
import '../lotto_database_erweitert.dart';
import 'statistics_models.dart';

class ClusterService {
  Future<RangeDistribution> distribution({
    required String spieltyp,
    required List<RangeBucket> buckets,
    required int takeNumbersPerDraw,
    int euroOffset = 0,
  }) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp);
    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));

    final counts = <String, int>{ for (final b in buckets) b.label: 0 };

    for (final z in sorted) {
      final nums = _extract(z, takeNumbersPerDraw: takeNumbersPerDraw, euroOffset: euroOffset);
      for (final n in nums) {
        for (final b in buckets) {
          if (b.contains(n)) {
            counts[b.label] = (counts[b.label] ?? 0) + 1;
            break;
          }
        }
      }
    }

    return RangeDistribution(spieltyp: spieltyp, buckets: buckets, counts: counts);
  }

  List<int> _extract(LottoZiehung z, {required int takeNumbersPerDraw, required int euroOffset}) {
    if (z.zahlen.length < euroOffset + takeNumbersPerDraw) return const [];
    return z.zahlen.sublist(euroOffset, euroOffset + takeNumbersPerDraw);
  }
}
