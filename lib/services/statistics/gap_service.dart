import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class GapService {
  final LottoDatabase db = LottoDatabase();

  Future<List<GapStats>> gaps({
    required String spieltyp,
    int minNumber = 1,
    int maxNumber = 49,
    int takeNumbersPerDraw = 6,
    int euroOffset = 0,
  }) async {
    final database = await db.database;
    final draws = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
    );

    final gapCounts = <int, int>{};
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList()..sort();
      
      // Berücksichtige nur bestimmte Zahlen
      final relevantNumbers = takeNumbersPerDraw > 0 && numbers.length > euroOffset
          ? numbers.sublist(euroOffset, euroOffset + takeNumbersPerDraw)
          : numbers;
          
      // Berechne Abstände zwischen aufeinanderfolgenden Zahlen
      for (int i = 1; i < relevantNumbers.length; i++) {
        final gap = relevantNumbers[i] - relevantNumbers[i - 1];
        gapCounts[gap] = (gapCounts[gap] ?? 0) + 1;
      }
    }

    return gapCounts.entries.map((e) => GapStats(gap: e.key, count: e.value)).toList();
  }
}
