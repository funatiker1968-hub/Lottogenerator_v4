import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  print('Teste Datenbank-Import...');
  
  // 1. Prüfe, ob Asset existiert
  try {
    final lottoContent = await rootBundle.loadString('assets/data/lotto_1955_2025.txt');
    print('✅ Asset gefunden: ${lottoContent.split('\n').length} Zeilen');
  } catch (e) {
    print('❌ Asset-Fehler: $e');
    return;
  }
  
  // 2. Datenbank öffnen (sollte Import auslösen)
  final path = join(await getDatabasesPath(), 'lotto.db');
  final db = await openDatabase(path, version: 1);
  
  // 3. Zählung prüfen
  final count = await db.rawQuery('SELECT COUNT(*) FROM ziehungen');
  print('📊 Ziehungen in DB: ${count.first.values.first}');
  
  await db.close();
}
