import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'lottodaten.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE lotto (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            datum TEXT NOT NULL,
            zahlen TEXT NOT NULL,
            superzahl INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE eurojackpot (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            datum TEXT NOT NULL,
            zahlen TEXT NOT NULL,
            eurozahlen TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> clear(String table) async {
    final d = await db;
    await d.delete(table);
  }

  static Future<void> insert(String table, Map<String, Object?> values) async {
    final d = await db;
    await d.insert(table, values);
  }
}
