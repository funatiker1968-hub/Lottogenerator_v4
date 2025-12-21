import '../../models/lotto_data.dart';
import '../lotto_database_erweitert.dart';


class ParityService {
  Future<Map<String, int>> parityHistogram({
    required String spieltyp,
    required int takeNumbersPerDraw,
    int euroOffset = 0,
  }) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp);
    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));

    final hist = <String, int>{};
    for (final z in sorted) {
      final nums = _extract(z, takeNumbersPerDraw: takeNumbersPerDraw, euroOffset: euroOffset);
      int even = 0;
      int odd = 0;
      for (final n in nums) {
        if (n % 2 == 0) {
          even++;
        } else {
          odd++;
        }
      }
      final key = '$even/$odd';
      hist[key] = (hist[key] ?? 0) + 1;
    }
    return hist;
  }

  List<int> _extract(LottoZiehung z, {required int takeNumbersPerDraw, required int euroOffset}) {
    if (z.zahlen.length < euroOffset + takeNumbersPerDraw) return const [];
    return z.zahlen.sublist(euroOffset, euroOffset + takeNumbersPerDraw);
  }
}
