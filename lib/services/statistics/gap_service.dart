import '../../models/lotto_data.dart';
import '../lotto_database_erweitert.dart';
import 'statistics_models.dart';

class GapService {
  Future<List<GapStats>> gaps({
    required String spieltyp,
    required int minNumber,
    required int maxNumber,
    required int takeNumbersPerDraw,
    int euroOffset = 0,
  }) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp);
    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));

    // positions per draw: 0..len-1
    final lastSeen = <int, int>{}; // number -> drawIndex
    final gaps = <int, List<int>>{}; // number -> list of gaps
    final occurrences = <int, int>{};

    for (int i = 0; i < sorted.length; i++) {
      final nums = _extract(sorted[i], takeNumbersPerDraw: takeNumbersPerDraw, euroOffset: euroOffset);
      for (final n in nums) {
        occurrences[n] = (occurrences[n] ?? 0) + 1;
        final prev = lastSeen[n];
        if (prev != null) {
          final gap = i - prev;
          (gaps[n] ??= <int>[]).add(gap);
        }
        lastSeen[n] = i;
      }
    }

    final res = <GapStats>[];
    for (int n = minNumber; n <= maxNumber; n++) {
      final list = gaps[n] ?? const <int>[];
      final occ = occurrences[n] ?? 0;

      int? minGap;
      int? maxGap;
      double? avgGap;

      if (list.isNotEmpty) {
        minGap = list.reduce((a, b) => a < b ? a : b);
        maxGap = list.reduce((a, b) => a > b ? a : b);
        final sum = list.fold<int>(0, (p, e) => p + e);
        avgGap = sum / list.length;
      }

      final currentGap = (lastSeen[n] == null) ? sorted.length : (sorted.length - 1 - lastSeen[n]!);

      res.add(GapStats(
        number: n,
        occurrences: occ,
        minGap: minGap,
        maxGap: maxGap,
        avgGap: avgGap,
        currentGap: currentGap,
      ));
    }

    // sort: most "overdue" first
    res.sort((a, b) => b.currentGap.compareTo(a.currentGap));
    return res;
  }

  List<int> _extract(LottoZiehung z, {required int takeNumbersPerDraw, required int euroOffset}) {
    if (z.zahlen.length < euroOffset + takeNumbersPerDraw) return const [];
    return z.zahlen.sublist(euroOffset, euroOffset + takeNumbersPerDraw);
  }
}
