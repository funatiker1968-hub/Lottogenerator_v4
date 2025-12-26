void testComment(String line, String year) {
  print("Test '$year': '$line'");
  
  final trimmed = line.trim();
  print("  Getrimmt: '$trimmed'");
  print("  Startet mit '#': ${trimmed.startsWith('#')}");
  print("  Split by '|': ${line.split('|').length} Teile");
  
  // Simuliere Parser-Logik
  if (trimmed.isEmpty || trimmed.startsWith('#')) {
    print("  ⏭️  Würde übersprungen werden");
  } else {
    print("  ❌ Würde als Datenzeile behandelt → FEHLER!");
  }
  print("");
}

void main() {
  // Test mit verschiedenen Kommentar-Formaten
  testComment("# 2022", "2022");
  testComment("# 2023", "2023");
  testComment("#2023", "2023 ohne Leerzeichen");
  testComment("# 2023 ", "2023 mit Leerzeichen am Ende");
  testComment(" # 2023", "2023 mit Leerzeichen am Anfang");
}
