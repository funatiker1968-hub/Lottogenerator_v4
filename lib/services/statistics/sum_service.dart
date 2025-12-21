import '../../models/lotto_data.dart';
import '../lotto_database_erweitert.dart';
import 'statistics_models.dart';

class SumService {
  Future<SumStats> sumStats({
    required String spieltyp,
    required int takeNumbersPerDraw,
    int euroOffset = 0,
  }) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp);
    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));

    if (sorted.isEmpty) {
      return const SumStats(spieltyp: 'none', countDraws: 0, minSum: 0, maxSum: 0, avgSum: 0);
    }

    int minSum = 1 << 30;
    int maxSum = 0;
    int sumAll = 0;
    int count = 0;

    for (final z in sorted) {
      final nums = _extract(z, takeNumbersPerDraw: takeNumbersPerDraw, euroOffset: euroOffset);
      if (nums.isEmpty) continue;
      final s = nums.fold<int>(0, (p, e) => p + e);
      minSum = s < minSum ? s : minSum;
      maxSum = s > maxSum ? s : maxSum;
      sumAll += s;
      count++;
    }

    return SumStats(
      spieltyp: spieltyp,
      countDraws: count,
      minSum: minSum == (1 << 30) ? 0 : minSum,
      maxSum: maxSum,
      avgSum: count == 0 ? 0 : (sumAll / count),
    );
  }

  Map<int, int> sumHistogram({
    required List<List<int>> drawsNumbers,
    int bucketSize = 10,
  }) {
    final hist = <int, int>{}; // bucketStart -> count
    for (final nums in drawsNumbers) {
      final s = nums.fold<int>(0, (p, e) => p + e);
      final b = (s ~/ bucketSize) * bucketSize;
      hist[b] = (hist[b] ?? 0) + 1;
    }
    return hist;
  }

  List<int> _extract(LottoZiehung z, {required int takeNumbersPerDraw, required int euroOffset}) {
    if (z.zahlen.length < euroOffset + takeNumbersPerDraw) return const [];
    return z.zahlen.sublist(euroOffset, euroOffset + takeNumbersPerDraw);
  }
}
