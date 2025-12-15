import '../../models/lotto_data.dart';
import '../lotto_database_erweitert.dart';
import 'statistics_models.dart';

class PairService {
  Future<PairResult> pairs({
    required String spieltyp,
    required int takeNumbersPerDraw,
    int euroOffset = 0,
  }) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp: spieltyp);
    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));

    final counts = <PairKey, int>{};

    for (final z in sorted) {
      final nums = _extract(z, takeNumbersPerDraw: takeNumbersPerDraw, euroOffset: euroOffset);
      if (nums.length < 2) continue;
      final sortedNums = List<int>.from(nums)..sort();

      for (int i = 0; i < sortedNums.length; i++) {
        for (int j = i + 1; j < sortedNums.length; j++) {
          final key = PairKey(sortedNums[i], sortedNums[j]);
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }

    return PairResult(spieltyp: spieltyp, counts: counts);
  }

  List<int> _extract(LottoZiehung z, {required int takeNumbersPerDraw, required int euroOffset}) {
    if (z.zahlen.length < euroOffset + takeNumbersPerDraw) return const [];
    return z.zahlen.sublist(euroOffset, euroOffset + takeNumbersPerDraw);
  }
}
