import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  try {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'lotto_database.db');
    
    final db = await openDatabase(dbPath);
    
    // Suche nach 04-01-2023 (konvertiertes Format)
    final results = await db.rawQuery('''
      SELECT * FROM ziehungen 
      WHERE spieltyp = ? AND datum = ?
    ''', ['lotto_6aus49', '04-01-2023']);
    
    print('Gefundene Einträge für 04-01-2023: ${results.length}');
    
    if (results.isNotEmpty) {
      print('❌ DUPLIKAT GEFUNDEN!');
      print('Eintrag: ${results.first}');
    } else {
      print('✅ Kein Duplikat gefunden');
    }
    
    await db.close();
  } catch (e) {
    print('❌ Fehler: $e');
  }
}
