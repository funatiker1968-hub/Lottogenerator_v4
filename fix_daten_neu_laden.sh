#!/bin/bash

# Finde die _startImport Methode
START_LINE=$(grep -n "Future<void> _startImport() async" lib/screens/database_status_screen.dart | cut -d: -f1)
if [ -z "$START_LINE" ]; then
  echo "❌ _startImport Methode nicht gefunden"
  exit 1
fi

# Finde das Ende der Methode
END_LINE=$(sed -n "$START_LINE,\$p" lib/screens/database_status_screen.dart | grep -n -m 1 "^  \w" | cut -d: -f1)
if [ -z "$END_LINE" ]; then
  END_LINE=$(wc -l < lib/screens/database_status_screen.dart)
else
  END_LINE=$((START_LINE + END_LINE - 2))
fi

echo "Ersetze _startImport von Zeile $START_LINE bis $END_LINE"

# Ersetze durch KORRIGIERTE Version mit echtem DB-Reset
sed -i "${START_LINE},${END_LINE}d" lib/screens/database_status_screen.dart

sed -i "${START_LINE}i\\
  Future<void> _startImport() async {\\
    if (_isImporting) return;\\
    \\
    setState(() {\\
      _isImporting = true;\\
      _importProgress = 0.0;\\
    });\\
    \\
    _addLog(LogType.info, '🚀 STARTE DATENBANK-RESET UND NEULADEN...');\\
    \\
    try {\\
      final db = LottoDatabase();\\
      \\
      // SCHRITT 1: DATENBANK LEEREN\\
      setState(() { _importProgress = 0.1; });\\
      _addLog(LogType.info, '🗑️  Leere Datenbank...');\\
      \\
      final database = await db.database;\\
      await database.delete('ziehungen');\\
      \\
      _addLog(LogType.success, '✅ Datenbank geleert.');\\
      setState(() { _importProgress = 0.3; });\\
      await Future.delayed(const Duration(milliseconds: 500));\\
      \\
      // SCHRITT 2: IMPORT AUS TXT-DATEIEN\\
      _addLog(LogType.info, '📥 Importiere Lotto 6aus49 aus TXT...');\\
      setState(() { _importProgress = 0.4; });\\
      \\
      // Lotto-Daten importieren (aus assets/data/lotto_1955_2025.txt)\\
      try {\\
        final content = await rootBundle.loadString('assets/data/lotto_1955_2025.txt');\\
        final lines = content.split('\\\\n');\\
        int lottoImported = 0;\\
        \\
        for (final line in lines) {\\
          if (line.trim().isEmpty) continue;\\
          final parts = line.split('|');\\
          if (parts.length != 3) continue;\\
          \\
          // Format: dd.mm.yyyy | z1 z2 z3 z4 z5 z6 | sz\\
          final datum = parts[0].trim();\\
          final zahlen = parts[1].trim();\\
          final superzahl = int.tryParse(parts[2].trim()) ?? 0;\\
          \\
          // Konvertiere datum von dd.mm.yyyy zu dd-mm-yyyy\\
          final datumParts = datum.split('.');\\
          final dbDatum = '\${datumParts[0]}-\${datumParts[1]}-\${datumParts[2]}';\\
          \\
          await database.insert('ziehungen', {\\
            'spieltyp': 'lotto_6aus49',\\
            'datum': dbDatum,\\
            'zahlen': zahlen,\\
            'superzahl': superzahl\\
          });\\
          \\
          lottoImported++;\\
          \\
          // Fortschritt aktualisieren (0.4 - 0.7 für Lotto)\\
          if (lottoImported % 100 == 0) {\\
            final progress = 0.4 + (0.3 * lottoImported / lines.length);\\
            setState(() { _importProgress = progress; });\\
            _addLog(LogType.info, 'Lotto Import: \$lottoImported/\${lines.length}');\\
          }\\
        }\\
        \\
        _addLog(LogType.success, '✅ \$lottoImported Lotto-Ziehungen importiert.');\\
        setState(() { _importProgress = 0.7; });\\
      } catch (e) {\\
        _addLog(LogType.error, '❌ Lotto-Import Fehler: \$e');\\
      }\\
      \\
      // SCHRITT 3: EUROJACKPOT IMPORTIEREN\\
      _addLog(LogType.info, '📥 Importiere Eurojackpot aus TXT...');\\
      setState(() { _importProgress = 0.75; });\\
      \\
      try {\\
        final content = await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');\\
        final lines = content.split('\\\\n');\\
        int ejImported = 0;\\
        \\
        for (final line in lines) {\\
          if (line.trim().isEmpty) continue;\\
          final parts = line.split('|');\\
          if (parts.length != 3) continue;\\
          \\
          // Format: yyyy-mm-dd | h1 h2 h3 h4 h5 | e1 e2\\
          final datum = parts[0].trim();\\
          final zahlen = parts[1].trim() + ' ' + parts[2].trim(); // Haupt + Euro zusammen\\
          \\
          await database.insert('ziehungen', {\\
            'spieltyp': 'eurojackpot',\\
            'datum': datum,\\
            'zahlen': zahlen,\\
            'superzahl': 0\\
          });\\
          \\
          ejImported++;\\
          \\
          // Fortschritt aktualisieren (0.75 - 0.95 für Eurojackpot)\\
          if (ejImported % 50 == 0) {\\
            final progress = 0.75 + (0.2 * ejImported / lines.length);\\
            setState(() { _importProgress = progress; });\\
            _addLog(LogType.info, 'Eurojackpot Import: \$ejImported/\${lines.length}');\\
          }\\
        }\\
        \\
        _addLog(LogType.success, '✅ \$ejImported Eurojackpot-Ziehungen importiert.');\\
        setState(() { _importProgress = 0.95; });\\
      } catch (e) {\\
        _addLog(LogType.error, '❌ Eurojackpot-Import Fehler: \$e');\\
      }\\
      \\
      // SCHRITT 4: ABSCHLUSS\\
      _addLog(LogType.success, '🎉 DATENBANK-RESET ABGESCHLOSSEN!');\\
      setState(() { _importProgress = 1.0; });\\
      \\
      // Statistik aktualisieren\\
      await Future.delayed(const Duration(seconds: 1));\\
      _loadDatabaseInfo();\\
      \\
      // Progress nach 2 Sekunden zurücksetzen\\
      Future.delayed(const Duration(seconds: 2), () {\\
        if (mounted) {\\
          setState(() {\\
            _importProgress = 0.0;\\
          });\\
        }\\
      });\\
      \\
    } catch (e) {\\
      _addLog(LogType.error, '❌ FEHLER beim Datenbank-Reset: \$e');\\
    } finally {\\
      if (mounted) {\\
        setState(() {\\
          _isImporting = false;\\
        });\\
      }\\
    }\\
  }" lib/screens/database_status_screen.dart

echo "✅ _startImport korrigiert - Jetzt löscht UND füllt der Button die DB!"
echo ""
echo "⚠️  WICHTIG: Füge noch rootBundle Import hinzu (falls fehlt)"
echo "Prüfe ob diese Importe existieren:"
echo "import 'package:flutter/services.dart'; // für rootBundle"
