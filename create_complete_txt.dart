import 'dart:convert';
import 'dart:io';

void main() async {
  final jsonPath = 'assets/data/Lottonumbers_complete.json';
  final outputPath = 'assets/data/lotto_complete_1955_2025.txt';

  print('📂 Lese JSON...');
  final jsonFile = File(jsonPath);
  final jsonString = await jsonFile.readAsString();
  final Map<String, dynamic> decoded = json.decode(jsonString);
  final List<dynamic> data = decoded['data'];
  print('   Gefunden: ${data.length} Einträge.');

  final outputFile = File(outputPath);
  final sink = outputFile.openWrite();

  for (final entry in data) {
    // DATUM: Bereits als "DD.MM.YYYY" vorhanden → direkt verwenden
    final rawDate = entry['date']?.toString() ?? '';
    if (rawDate.isEmpty) continue;

    // ZAHLEN: Als Liste extrahieren
    final rawNumbers = entry['numbers'];
    if (rawNumbers is! List<dynamic>) continue;
    final zahlenStr = rawNumbers.map((n) => n.toString()).join(' ');

    // SUPERZAHL
    final superzahl = entry['superzahl']?.toString() ?? 
                      entry['additionalNumber']?.toString() ?? 
                      entry['superNumber']?.toString() ?? '0';

    // Schreibe Zeile: DATUM bleibt DD.MM.YYYY
    sink.writeln('$rawDate | $zahlenStr | $superzahl');
  }

  await sink.close();
  print('✅ Neue TXT erstellt: $outputPath');

  final lines = await outputFile.readAsLines();
  print('   Zeilen: ${lines.length}');
  print('   Erste Zeile: ${lines.first}');
  print('   Letzte Zeile: ${lines.last}');
}
