#!/bin/bash

echo "🔄 Ersetze _triggerReimport Methode..."

# Finde Start und Ende der Methode
START_LINE=$(grep -n "Future<void> _triggerReimport() async {" lib/screens/database_status_screen.dart | cut -d: -f1)
if [ -z "$START_LINE" ]; then
  echo "❌ Methode nicht gefunden"
  exit 1
fi

# Finde Ende (nächste Methode die mit Leerzeichen beginnt)
END_LINE=$(sed -n "$START_LINE,\$p" lib/screens/database_status_screen.dart | grep -n -m 1 "^  [a-zA-Z]" | cut -d: -f1)
if [ -z "$END_LINE" ]; then
  END_LINE=$(wc -l < lib/screens/database_status_screen.dart)
else
  END_LINE=$((START_LINE + END_LINE - 2))
fi

echo "Ersetze Zeilen $START_LINE bis $END_LINE"

# Lösche alte Methode
sed -i "${START_LINE},${END_LINE}d" lib/screens/database_status_screen.dart

# Füge korrigierte Methode ein
sed -i "${START_LINE}i\\
  Future<void> _triggerReimport() async {\\
    setState(() {\\
      _importing = true;\\
      _importProgress = 0.0;\\
    });\\
\\
    _addLog('🚀 START: Kompletter Neu-Import aus TXT-Dateien', type: LogType.warning);\\
\\
    try {\\
      final database = await _db.database;\\
\\
      // SCHRITT 1: DATENBANK LEEREN\\
      _updateProgress(0.1, 'Lösche alte Daten...');\\
      await database.delete('ziehungen');\\
      _addLog('✅ Alte Daten gelöscht', type: LogType.success);\\
\\
      // SCHRITT 2: LOTTO 6AUS49 IMPORTIEREN\\
      _updateProgress(0.2, 'Importiere Lotto 6aus49...');\\
      _addLog('📥 Lese Lotto-Daten...', type: LogType.info);\\
      \\
      try {\\
        // Lotto-Daten aus TXT importieren\\
        final content = await rootBundle.loadString('assets/data/lotto_1955_2025.txt');\\
        final lines = content.split('\\\\n');\\
        int imported = 0;\\
        int total = lines.length;\\
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
          // Datum konvertieren: dd.mm.yyyy → dd-mm-yyyy\\
          final datumParts = datum.split('.');\\
          if (datumParts.length == 3) {\\
            final dbDatum = '\${datumParts[0]}-\${datumParts[1]}-\${datumParts[2]}';\\
\\
            await database.insert('ziehungen', {\\
              'spieltyp': 'lotto_6aus49',\\
              'datum': dbDatum,\\
              'zahlen': zahlen,\\
              'superzahl': superzahl\\
            });\\
\\
            imported++;\\
          }\\
\\
          // Fortschritt aktualisieren\\
          if (imported % 100 == 0) {\\
            final progress = 0.2 + (0.4 * imported / total);\\
            _updateProgress(progress, 'Lotto: \$imported/\$total');\\
          }\\
        }\\
\\
        _addLog('✅ \$imported Lotto-Ziehungen importiert', type: LogType.success);\\
        _updateProgress(0.6, 'Lotto-Import abgeschlossen');\\
\\
      } catch (e) {\\
        _addLog('❌ Lotto-Import Fehler: \$e', type: LogType.error);\\
      }\\
\\
      // SCHRITT 3: EUROJACKPOT IMPORTIEREN\\
      _updateProgress(0.65, 'Importiere Eurojackpot...');\\
      _addLog('📥 Lese Eurojackpot-Daten...', type: LogType.info);\\
\\
      try {\\
        final content = await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');\\
        final lines = content.split('\\\\n');\\
        int imported = 0;\\
        int total = lines.length;\\
\\
        for (final line in lines) {\\
          if (line.trim().isEmpty) continue;\\
          final parts = line.split('|');\\
          if (parts.length != 3) continue;\\
\\
          // Format: yyyy-mm-dd | h1 h2 h3 h4 h5 | e1 e2\\
          final datum = parts[0].trim();\\
          final hauptzahlen = parts[1].trim();\\
          final eurozahlen = parts[2].trim();\\
          final zahlen = '\$hauptzahlen \$eurozahlen';\\
\\
          await database.insert('ziehungen', {\\
            'spieltyp': 'eurojackpot',\\
            'datum': datum,\\
            'zahlen': zahlen,\\
            'superzahl': 0\\
          });\\
\\
          imported++;\\
\\
          // Fortschritt aktualisieren\\
          if (imported % 50 == 0) {\\
            final progress = 0.65 + (0.3 * imported / total);\\
            _updateProgress(progress, 'Eurojackpot: \$imported/\$total');\\
          }\\
        }\\
\\
        _addLog('✅ \$imported Eurojackpot-Ziehungen importiert', type: LogType.success);\\
        _updateProgress(0.95, 'Eurojackpot-Import abgeschlossen');\\
\\
      } catch (e) {\\
        _addLog('❌ Eurojackpot-Import Fehler: \$e', type: LogType.error);\\
      }\\
\\
      // SCHRITT 4: ABSCHLUSS\\
      await Future.delayed(const Duration(milliseconds: 500));\\
      _updateProgress(1.0, 'Import komplett abgeschlossen');\\
      \\
      _addLog('🎉 DATENBANK NEU GELADEN: Lotto + Eurojackpot', type: LogType.success);\\
      _addLog('ℹ️  Statistik wird aktualisiert...', type: LogType.info);\\
\\
      await _loadStats();\\
\\
    } catch (e) {\\
      _addLog('❌ IMPORT FEHLGESCHLAGEN: \$e', type: LogType.error);\\
    } finally {\\
      setState(() => _importing = false);\\
    }\\
  }" lib/screens/database_status_screen.dart

echo "✅ Methode ersetzt!"
echo ""
echo "🧪 Prüfe Syntax..."
dart analyze lib/screens/database_status_screen.dart --no-pub 2>&1 | grep -E "error •" | head -5 || echo "✅ Keine Syntax-Fehler"
