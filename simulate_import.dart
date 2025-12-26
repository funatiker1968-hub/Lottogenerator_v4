// Reines Dart - keine Flutter/sqfLite Abhängigkeiten
// Simuliert die importLotto6aus49Line Logik

void simulateImport(String line) {
  print('=== IMPORT-SIMULATION FÜR: "$line" ===');
  
  try {
    // 1. Trimmen
    final trimmedLine = line.trim();
    print('1. Getrimmt: "$trimmedLine"');
    
    // 2. Aufteilen
    final parts = trimmedLine.split('|');
    print('2. Split in ${parts.length} Teile');
    
    if (parts.length != 3) {
      throw FormatException('Nicht genau 3 Teile (erwartet: datum|zahlen|sz)');
    }
    
    // 3. Teile extrahieren
    final dateStr = parts[0].trim();
    final numbersStr = parts[1].trim();
    final superzahlStr = parts[2].trim();
    
    print('3. Datum: "$dateStr"');
    print('   Zahlen: "$numbersStr"');
    print('   Superzahl: "$superzahlStr"');
    
    // 4. Datum parsen und konvertieren
    final dateParts = dateStr.split('.');
    if (dateParts.length != 3) {
      throw FormatException('Datum nicht im Format dd.mm.yyyy');
    }
    
    final day = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);
    
    // Konvertiere zu DB-Format: dd-mm-yyyy
    final dbDate = '${day.toString().padLeft(2, "0")}-'
                   '${month.toString().padLeft(2, "0")}-'
                   '$year';
    
    print('4. Datum geparst: Tag=$day, Monat=$month, Jahr=$year');
    print('   DB-Format: "$dbDate"');
    
    // 5. Zahlen parsen und validieren
    final numbers = numbersStr.split(' ').map((n) {
      final num = int.parse(n.trim());
      if (num < 1 || num > 49) {
        throw FormatException('Zahl $num außerhalb 1-49');
      }
      return num;
    }).toList();
    
    if (numbers.length != 6) {
      throw FormatException('Nicht genau 6 Zahlen (gefunden: ${numbers.length})');
    }
    
    numbers.sort();
    final zahlen = numbers.join(' ');
    
    print('5. Zahlen geparst: $numbers');
    print('   Sortiert: $zahlen');
    
    // 6. Superzahl parsen mit historischer Korrektur
    int superzahl;
    try {
      superzahl = int.parse(superzahlStr);
      
      // Historische Korrektur: Vor 7.12.1991 keine Superzahl
      final date = DateTime(year, month, day);
      final superzahlEinfuehrung = DateTime(1991, 12, 7);
      
      if (date.isBefore(superzahlEinfuehrung)) {
        superzahl = -1;
        print('   Historische Korrektur: Vor 7.12.1991 → Superzahl = -1');
      }
    } catch (e) {
      superzahl = -1;
      print('   Superzahl Parse-Fehler → auf -1 gesetzt');
    }
    
    print('6. Superzahl: $superzahl');
    
    // 7. Simulierter Datenbank-Insert
    print('7. 🗄️  SIMULIERTER DB-INSERT:');
    print('   spieltyp: "lotto_6aus49"');
    print('   datum: "$dbDate"');
    print('   zahlen: "$zahlen"');
    print('   superzahl: $superzahl');
    
    print('\n✅ SIMULATION ERFOLGREICH - Zeile wäre importiert worden!');
    
  } catch (e) {
    print('\n❌ SIMULATION FEHLGESCHLAGEN:');
    print('   Fehler: $e');
    print('   Typ: ${e.runtimeType}');
    
    // Stacktrace für genauere Analyse
    if (e is FormatException) {
      print('   Message: ${e.message}');
    }
  }
  
  print('=' * 50);
}

void main() {
  print('🧪 IMPORT-SIMULATION (ohne Flutter/sqfLite)');
  print('');
  
  // Test mit der Problemzeile
  simulateImport('04.01.2023 | 19 29 31 34 37 47 | 0');
  
  print('');
  print('📋 Vergleich mit erfolgreicher Zeile:');
  simulateImport('31.12.2022 | 4 13 16 18 32 46 | 8');
  
  print('');
  print('🧪 Weitere Tests:');
  
  // Test mit möglichen Problemfällen
  final testCases = [
    '04.01.2023|19 29 31 34 37 47|0',      // Ohne Leerzeichen um |
    '04.01.2023 | 19 29 31 34 37 47 | 0 ', // Leerzeichen am Ende
    ' 04.01.2023 | 19 29 31 34 37 47 | 0', // Leerzeichen am Anfang
    '04.01.2023 | 19 29 31 34 37 47 |',    // Fehlende Superzahl
    '04.01.2023 | 19 29 31 34 37 | 0',     // Nur 5 Zahlen
    '04.01.2023 | 19 29 31 34 37 47 48 | 0', // 7 Zahlen
    '04.01.2023 | 19 29 31 34 37 60 | 0',  // Zahl > 49
    '04.01.2023 | 19 29 31 34 37 0 | 0',   // Zahl = 0
  ];
  
  for (int i = 0; i < testCases.length; i++) {
    print('\nTest ${i + 1}:');
    simulateImport(testCases[i]);
  }
}
