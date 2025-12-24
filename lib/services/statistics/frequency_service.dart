import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class FrequencyService {
  final LottoDatabase db = LottoDatabase();

  Future<FrequencyResult> frequency({
    required String spieltyp,
    int lastNDraws = 0,
    bool superzahl = false,
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
    
    final frequency = <int, int>{};
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      
      // Berücksichtige nur bestimmte Zahlen pro Ziehung (z.B. 5 für EJ Hauptzahlen)
      final numbersToCount = takeNumbersPerDraw > 0 && numbers.length > euroOffset
          ? numbers.sublist(euroOffset, euroOffset + takeNumbersPerDraw)
          : numbers;
          
      for (final num in numbersToCount) {
        frequency[num] = (frequency[num] ?? 0) + 1;
      }
      
      // Superzahl bei Lotto
      if (superzahl && spieltyp == '6aus49') {
        final sz = draw['superzahl'] as int? ?? -1;
        if (sz >= 0 && sz <= 9) {
          frequency[sz + 100] = (frequency[sz + 100] ?? 0) + 1; // Superzahlen offset
        }
      }
    }
    
    return FrequencyResult(
      spieltyp: spieltyp,
      frequency: frequency,
      draws: draws.length,
    );
  }
}
