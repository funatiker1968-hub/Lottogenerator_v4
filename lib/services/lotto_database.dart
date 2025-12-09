import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LottoDatabase {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    
    _database = await openDatabase(
      join(await getDatabasesPath(), 'lotto_database.db'),
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE ziehungen("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "datum TEXT NOT NULL,"
          "zahlen TEXT NOT NULL,"
          "superzahl INTEGER NOT NULL,"
          "spieltyp TEXT NOT NULL,"
          "UNIQUE(datum, spieltyp)"
          ")"
        );
        
        // Optional: Index für bessere Performance
        await db.execute(
          "CREATE INDEX idx_spieltyp_datum ON ziehungen(spieltyp, datum DESC)"
        );
      },
      version: 1,
    );
    return _database!;
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
