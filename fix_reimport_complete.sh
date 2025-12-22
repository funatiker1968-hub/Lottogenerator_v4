#!/bin/bash

echo "🔧 Erstelle vollständig korrigierte _triggerReimport Methode..."

# Prüfe ob rootBundle importiert ist
if ! grep -q "import 'package:flutter/services.dart';" lib/screens/database_status_screen.dart; then
  echo "➕ Füge rootBundle Import hinzu..."
  sed -i "1a import 'package:flutter/services.dart';" lib/screens/database_status_screen.dart
fi

# Ersetze die gesamte Methode
cat > /tmp/final_fix.dart << 'FINAL'
  Future<void> _triggerReimport() async {
    setState(() {
      _importing = true;
      _importProgress = 0.0;
    });

    _addLog('🚀 START: Kompletter Neu-Import aus TXT-Dateien', type: LogType.warning);

    try {
      final database = await _db.database;

      // SCHRITT 1: DATENBANK LEEREN
      _updateProgress(0.1, 'Lösche alte Daten...');
      await database.delete('ziehungen');
      _addLog('✅ Alte Daten gelöscht', type: LogType.success);

      // SCHRITT 2: LOTTO 6AUS49 IMPORTIEREN
      _updateProgress(0.2, 'Importiere Lotto 6aus49...');
      _addLog('📥 Lese Lotto-Daten...', type: LogType.info);
      
      try {
        // Lotto-Daten aus TXT importieren
        final content = await rootBundle.loadString('assets/data/lotto_1955_2025.txt');
        final lines = content.split('\n');
        int imported = 0;
        int total = lines.length;

        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('|');
          if (parts.length != 3) continue;

          // Format: dd.mm.yyyy | z1 z2 z3 z4 z5 z6 | sz
          final datum = parts[0].trim();
          final zahlen = parts[1].trim();
          final superzahl = int.tryParse(parts[2].trim()) ?? 0;

          // Datum konvertieren: dd.mm.yyyy → dd-mm-yyyy
          final datumParts = datum.split('.');
          if (datumParts.length == 3) {
            final dbDatum = '\${datumParts[0]}-\${datumParts[1]}-\${datumParts[2]}';

            await database.insert('ziehungen', {
              'spieltyp': 'lotto_6aus49',
              'datum': dbDatum,
              'zahlen': zahlen,
              'superzahl': superzahl
            });

            imported++;
          }

          // Fortschritt aktualisieren
          if (imported % 100 == 0) {
            final progress = 0.2 + (0.4 * imported / total);
            _updateProgress(progress, 'Lotto: \$imported/\$total');
          }
        }

        _addLog('✅ \$imported Lotto-Ziehungen importiert', type: LogType.success);
        _updateProgress(0.6, 'Lotto-Import abgeschlossen');

      } catch (e) {
        _addLog('❌ Lotto-Import Fehler: \$e', type: LogType.error);
      }

      // SCHRITT 3: EUROJACKPOT IMPORTIEREN
      _updateProgress(0.65, 'Importiere Eurojackpot...');
      _addLog('📥 Lese Eurojackpot-Daten...', type: LogType.info);

      try {
        final content = await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');
        final lines = content.split('\n');
        int imported = 0;
        int total = lines.length;

        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('|');
          if (parts.length != 3) continue;

          // Format: yyyy-mm-dd | h1 h2 h3 h4 h5 | e1 e2
          final datum = parts[0].trim();
          final hauptzahlen = parts[1].trim();
          final eurozahlen = parts[2].trim();
          final zahlen = '\$hauptzahlen \$eurozahlen';

          await database.insert('ziehungen', {
            'spieltyp': 'eurojackpot',
            'datum': datum,
            'zahlen': zahlen,
            'superzahl': 0
          });

          imported++;

          // Fortschritt aktualisieren
          if (imported % 50 == 0) {
            final progress = 0.65 + (0.3 * imported / total);
            _updateProgress(progress, 'Eurojackpot: \$imported/\$total');
          }
        }

        _addLog('✅ \$imported Eurojackpot-Ziehungen importiert', type: LogType.success);
        _updateProgress(0.95, 'Eurojackpot-Import abgeschlossen');

      } catch (e) {
        _addLog('❌ Eurojackpot-Import Fehler: \$e', type: LogType.error);
      }

      // SCHRITT 4: ABSCHLUSS
      await Future.delayed(const Duration(milliseconds: 500));
      _updateProgress(1.0, 'Import komplett abgeschlossen');
      
      _addLog('🎉 DATENBANK NEU GELADEN: Lotto + Eurojackpot', type: LogType.success);
      _addLog('ℹ️  Statistik wird aktualisiert...', type: LogType.info);

      await _loadStats();

    } catch (e) {
      _addLog('❌ IMPORT FEHLGESCHLAGEN: \$e', type: LogType.error);
    } finally {
      setState(() => _importing = false);
    }
  }
FINAL

echo "✅ Korrigierte Methode erstellt."
echo ""
echo "📋 KORREKTUREN in _triggerReimport():"
echo "1. ✅ ECHTER Import aus TXT-Dateien (nicht nur Fake)"
echo "2. ✅ Lotto 6aus49: assets/data/lotto_1955_2025.txt"
echo "3. ✅ Eurojackpot: assets/data/eurojackpot_2012_2025.txt"  
echo "4. ✅ Echter Fortschrittsbalken basierend auf importierten Datensätzen"
echo "5. ✅ Detaillierte Log-Ausgaben für jeden Schritt"
echo ""
echo "👉 Jetzt ersetzen wir die alte Methode..."
