import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class EurojackpotDbService {
  EurojackpotDbService._();
  static final EurojackpotDbService instance = EurojackpotDbService._();

  static const _dbName = 'eurojackpot.db';
  static const drawsTable = 'eurojackpot_draws';

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;
    final created = await _open();
    _db = created;
    return created;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: 1,
      onCreate: (Database d, int version) async {
        await d.execute('''
CREATE TABLE IF NOT EXISTS $drawsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  draw_date TEXT NOT NULL UNIQUE,
  n1 INTEGER NOT NULL,
  n2 INTEGER NOT NULL,
  n3 INTEGER NOT NULL,
  n4 INTEGER NOT NULL,
  n5 INTEGER NOT NULL,
  e1 INTEGER NOT NULL,
  e2 INTEGER NOT NULL
);
''');
        await d.execute('CREATE INDEX IF NOT EXISTS idx_ej_draw_date ON $drawsTable(draw_date);');
      },
    );
  }

  Future<int> countDraws() async {
    final d = await db;
    final res = await d.rawQuery('SELECT COUNT(*) AS c FROM $drawsTable');
    return (res.first['c'] as int?) ?? 0;
  }

  Future<void> upsertDraw({
    required String drawDate, // YYYY-MM-DD
    required int n1,
    required int n2,
    required int n3,
    required int n4,
    required int n5,
    required int e1,
    required int e2,
  }) async {
    final d = await db;
    await d.insert(
      drawsTable,
      {
        'draw_date': drawDate,
        'n1': n1,
        'n2': n2,
        'n3': n3,
        'n4': n4,
        'n5': n5,
        'e1': e1,
        'e2': e2,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // keine Dubletten
    );
  }
}
