import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'statistics_models.dart';

class DbInspectionService {
  final LottoDatabase db = LottoDatabase();

  Future<DbSummary> dbSummary({required String spieltyp}) async {
    final database = await db.database;
    
    final draws = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
    );
    
    if (draws.isEmpty) {
      return DbSummary(
        spieltyp: spieltyp,
        count: 0,
        firstDate: null,
        lastDate: null,
      );
    }
    
    // Find first and last dates
    DateTime? firstDate;
    DateTime? lastDate;
    
    for (final draw in draws) {
      final dateStr = draw['datum'] as String?;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        
        if (firstDate == null || date.isBefore(firstDate)) {
          firstDate = date;
        }
        if (lastDate == null || date.isAfter(lastDate)) {
          lastDate = date;
        }
      }
    }
    
    return DbSummary(
      spieltyp: spieltyp,
      count: draws.length,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
}
