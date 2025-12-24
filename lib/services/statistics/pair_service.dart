import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class PairService {
  final LottoDatabase db = LottoDatabase();

  Future<PairResult> pairs({required String spieltyp}) async {
    final database = await db.database;
    final draws = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
    );

    final pairCounts = <String, int>{};
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse).toList()..sort();
      
      // Erzeuge alle Paare
      for (int i = 0; i < numbers.length; i++) {
        for (int j = i + 1; j < numbers.length; j++) {
          final key = '${numbers[i]}-${numbers[j]}';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }

    final entries = pairCounts.entries.map((e) {
      final parts = e.key.split('-');
      return PairEntry(
        a: int.parse(parts[0]),
        b: int.parse(parts[1]),
        count: e.value,
      );
    }).toList();

    return PairResult(
      spieltyp: spieltyp,
      entries: entries,
    );
  }
}
