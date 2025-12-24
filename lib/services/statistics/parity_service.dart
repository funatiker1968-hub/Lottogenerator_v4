import 'package:lottogenerator_v4/services/lotto_database.dart';

class ParityService {
  final LottoDatabase db = LottoDatabase();

  Future<Map<String, int>> parity({required String spieltyp}) async {
    final database = await db.database;
    final draws = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
    );

    int gerade = 0;
    int ungerade = 0;
    
    for (final draw in draws) {
      final numbersStr = draw['zahlen'] as String;
      final numbers = numbersStr.split(' ').map(int.parse);
      
      for (final num in numbers) {
        if (num.isEven) {
          gerade++;
        } else {
          ungerade++;
        }
      }
    }

    return {
      'gerade': gerade,
      'ungerade': ungerade,
    };
  }
}
