import '../../models/lotto_data.dart';
import '../lotto_database.dart';
import 'statistics_models.dart';

class FrequencyService {
  /// Für Lotto 6aus49: nimmt 6 Zahlen je Ziehung.
  /// Für Eurojackpot: speichert bei euch 7 Zahlen in `zahlen` (5 Haupt + 2 Euro) -> hier flexibel steuerbar.
  Future<FrequencyResult> frequency({
    required String spieltyp,
    int lastNDraws = 0, // 0 = alle
    required int takeNumbersPerDraw, // lotto=6, ej-main=5, ej-euro=2
    int skipFromEnd = 0, // optional: z.B. "letzte Ziehung ausklammern"
    int euroOffset = 0, // ej-euro: offset=5
  }) async {
    final draws = await LottoDatabase.holeAlleZiehungen(spieltyp);
    if (draws.isEmpty) {
      return FrequencyResult(
        spieltyp: spieltyp,
        counts: const {},
        totalDraws: 0,
        numbersPerDraw: takeNumbersPerDraw,
      );
    }

    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));
    final effective = _slice(sorted, lastNDraws, skipFromEnd);

    final counts = <int, int>{};
    for (final z in effective) {
      final nums = _extract(z, takeNumbersPerDraw: takeNumbersPerDraw, euroOffset: euroOffset);
      for (final n in nums) {
        counts[n] = (counts[n] ?? 0) + 1;
      }
    }

    return FrequencyResult(
      spieltyp: spieltyp,
      counts: counts,
      totalDraws: effective.length,
      numbersPerDraw: takeNumbersPerDraw,
    );
  }

  List<LottoZiehung> _slice(List<LottoZiehung> sorted, int lastN, int skipFromEnd) {
    var end = sorted.length - skipFromEnd;
    if (end < 0) end = 0;
    var start = 0;
    if (lastN > 0) {
      start = end - lastN;
      if (start < 0) start = 0;
    }
    return sorted.sublist(start, end);
  }

  List<int> _extract(LottoZiehung z, {required int takeNumbersPerDraw, required int euroOffset}) {
    if (z.zahlen.length < euroOffset + takeNumbersPerDraw) return const [];
    return z.zahlen.sublist(euroOffset, euroOffset + takeNumbersPerDraw);
  }
}
