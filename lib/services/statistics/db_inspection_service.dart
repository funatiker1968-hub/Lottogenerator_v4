import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class DbInspectionService {
  final LottoDatabase db = LottoDatabase();

  Future<DbSummary> dbSummary({required String spieltyp}) async {
    final database = await db.database;
    
    final countResult = await database.rawQuery(
      "SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = ?",
      [spieltyp]
    );
    final count = countResult.first['count'] as int;
    
    final firstResult = await database.rawQuery(
      "SELECT MIN(datum) as first FROM ziehungen WHERE spieltyp = ?",
      [spieltyp]
    );
    final first = firstResult.first['first'] as String?;
    
    final lastResult = await database.rawQuery(
      "SELECT MAX(datum) as last FROM ziehungen WHERE spieltyp = ?",
      [spieltyp]
    );
    final last = lastResult.first['last'] as String?;
    
    return DbSummary(
      spieltyp: spieltyp,
      draws: count,
      firstDraw: first ?? '',
      lastDraw: last ?? '',
    );
  }
}
