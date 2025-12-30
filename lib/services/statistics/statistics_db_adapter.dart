import '../lotto_database.dart';
import '../../models/lotto_data.dart';

class StatisticsDbAdapter {
  final LottoDatabase _db = LottoDatabase.instance;

  Future<int> count(String spieltyp) async {
    final db = await _db.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ziehungen WHERE spieltyp = ?',
      [spieltyp],
    );
    return res.first['c'] as int;
  }

  Future<Map<String, DateTime>> range(String spieltyp) async {
    final db = await _db.database;
    final res = await db.rawQuery(
      'SELECT MIN(datum) AS first, MAX(datum) AS last FROM ziehungen WHERE spieltyp = ?',
      [spieltyp],
    );

    return {
      'first': DateTime.parse(res.first['first'] as String),
      'last': DateTime.parse(res.first['last'] as String),
    };
  }

  Future<Map<int, int>> frequency(String spieltyp, int take) async {
    final db = await _db.database;
    final rows = await db.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
    );

    final freq = <int, int>{};

    for (final r in rows) {
      final zahlen = (r['zahlen'] as String)
          .split(' ')
          .map(int.parse)
          .take(take);

      for (final z in zahlen) {
        freq[z] = (freq[z] ?? 0) + 1;
      }
    }
    return freq;
  }
}
