import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class GapService {
  final LottoDatabase db = LottoDatabase();

  Future<List<GapStats>> gaps({
    required String spieltyp,
    int lastNDraws = 0,
    int minNumber = 1,
    int maxNumber = 49,
    bool superzahl = false,
    int takeNumbersPerDraw = 6,
    int euroOffset = 0,
  }) async {
    final database = await db.database;
    
    String query = "SELECT * FROM ziehungen WHERE spieltyp = ? ORDER BY datum DESC";
    final args = [spieltyp];
    
    if (lastNDraws > 0) {
      query = "SELECT * FROM ziehungen WHERE spieltyp = ? ORDER BY datum DESC LIMIT ?";
      args.add(lastNDraws.toString());
    }
    
    final draws = await database.rawQuery(query, args);
    final reversedDraws = draws.reversed.toList(); // Älteste zuerst
    
    final Map<int, List<int>> numberDrawIndices = {};
    final Map<int, int> lastSeenAt = {};
    
    // Zuerst alle Vorkommen sammeln
    for (int drawIdx = 0; drawIdx < reversedDraws.length; drawIdx++) {
      final draw = reversedDraws[drawIdx];
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      
      final numbersToCheck = takeNumbersPerDraw > 0 && numbers.length > euroOffset
          ? numbers.sublist(euroOffset, euroOffset + takeNumbersPerDraw)
          : numbers;
      
      for (final num in numbersToCheck) {
        if (num >= minNumber && num <= maxNumber) {
          numberDrawIndices.putIfAbsent(num, () => []).add(drawIdx);
          lastSeenAt[num] = drawIdx;
        }
      }
    }
    
    final List<GapStats> results = [];
    
    for (int num = minNumber; num <= maxNumber; num++) {
      final indices = numberDrawIndices[num] ?? [];
      final occurrences = indices.length;
      
      if (occurrences == 0) {
        results.add(GapStats(
          number: num,
          occurrences: 0,
          minGap: null,
          maxGap: null,
          avgGap: null,
          currentGap: reversedDraws.length,
        ));
        continue;
      }
      
      // Lücken zwischen Vorkommen berechnen
      final List<int> gaps = [];
      for (int i = 1; i < indices.length; i++) {
        gaps.add(indices[i] - indices[i - 1]);
      }
      
      final int minGap = gaps.isEmpty ? 0 : gaps.reduce((a, b) => a < b ? a : b);
      final int maxGap = gaps.isEmpty ? 0 : gaps.reduce((a, b) => a > b ? a : b);
      final double avgGap = gaps.isEmpty ? 0 : gaps.reduce((a, b) => a + b) / gaps.length;
      final int currentGap = reversedDraws.length - 1 - (lastSeenAt[num] ?? 0);
      
      results.add(GapStats(
        number: num,
        occurrences: occurrences,
        minGap: minGap,
        maxGap: maxGap,
        avgGap: avgGap,
        currentGap: currentGap,
      ));
    }
    
    // Sortieren nach currentGap (absteigend)
    results.sort((a, b) => b.currentGap.compareTo(a.currentGap));
    return results;
  }
}
