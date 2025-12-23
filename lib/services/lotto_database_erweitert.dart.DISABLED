import 'lotto_database.dart';
import '../models/lotto_data.dart';

class ErweiterteLottoDatenbank {
  static final LottoDatabase _db = LottoDatabase.instance;

  static Future<List<LottoZiehung>> holeAlleZiehungen(
    String spieltyp,
  ) async {
    final database = await _db.database;
    final rows = await database.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum ASC',
    );

    return rows.map(LottoZiehung.fromMap).toList();
  }

  static Future<int> zaehleZiehungen(String spieltyp) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = ?',
      [spieltyp],
    );
    return result.first['count'] as int;
  }

  static Future<Map<String, DateTime>> holeZeitraum(String spieltyp) async {
    final database = await _db.database;
    final result = await database.rawQuery('''
      SELECT MIN(datum) as first, MAX(datum) as last 
      FROM ziehungen WHERE spieltyp = ?
    ''', [spieltyp]);

    final row = result.first;
    return {
      'first': DateTime.parse(row['first'] as String),
      'last': DateTime.parse(row['last'] as String),
    };
  }
}
