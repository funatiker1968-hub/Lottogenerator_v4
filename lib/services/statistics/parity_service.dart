import 'package:lottogenerator_v4/services/lotto_database.dart';

class ParityService {
  final LottoDatabase db = LottoDatabase();

  Future<Map<String, int>> parity({
    required String spieltyp,
    int lastNDraws = 0,
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
    
    int evenCount = 0;
    int oddCount = 0;
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList();
      
      final numbersToCheck = takeNumbersPerDraw > 0 && numbers.length > euroOffset
          ? numbers.sublist(euroOffset, euroOffset + takeNumbersPerDraw)
          : numbers;
      
      for (final num in numbersToCheck) {
        if (num % 2 == 0) {
          evenCount++;
        } else {
          oddCount++;
        }
      }
    }
    
    return {
      'even': evenCount,
      'odd': oddCount,
    };
  }
}
