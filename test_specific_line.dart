// Simuliere die importLotto6aus49Line Logik
void testLine(String line) {
  print("Teste: '$line'");
  
  try {
    final trimmed = line.trim();
    
    if (trimmed.isEmpty) {
      print("❌ Leere Zeile");
      return;
    }
    
    final parts = trimmed.split('|');
    print("  Split in ${parts.length} Teile");
    
    if (parts.length != 3) {
      print("❌ Nicht 3 Teile!");
      return;
    }
    
    final dateStr = parts[0].trim();
    final numbersStr = parts[1].trim();
    final superzahlStr = parts[2].trim();
    
    print("  Datum: '$dateStr'");
    print("  Zahlen: '$numbersStr'");
    print("  Superzahl: '$superzahlStr'");
    
    // Datum parsen
    final dateParts = dateStr.split('.');
    if (dateParts.length != 3) {
      print("❌ Datum nicht dd.mm.yyyy");
      return;
    }
    
    final day = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);
    
    print("  Day: $day, Month: $month, Year: $year");
    
    // Zahlen parsen
    final numbers = numbersStr.split(' ').map(int.parse).toList();
    print("  ${numbers.length} Zahlen: $numbers");
    
    // Superzahl parsen
    final superzahl = int.parse(superzahlStr);
    print("  Superzahl: $superzahl");
    
    print("✅ ALLES OK - sollte importiert werden!");
    
  } catch (e) {
    print("❌ FEHLER: $e");
    print("  Fehlertyp: ${e.runtimeType}");
  }
}

void main() {
  testLine("04.01.2023 | 19 29 31 34 37 47 | 0");
}
