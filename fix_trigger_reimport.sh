#!/bin/bash

# Finde Start und Ende der _triggerReimport Methode
START_LINE=93
END_LINE=$(sed -n '93,$p' lib/screens/database_status_screen.dart | grep -n -m 1 "^  \w" | cut -d: -f1)
END_LINE=$((93 + END_LINE - 2))

echo "Ersetze _triggerReimport von Zeile $START_LINE bis $END_LINE"

# Erstelle korrigierte Version
cat > /tmp/corrected_reimport.txt << 'CORRECTED'
  Future<void> _triggerReimport() async {
    setState(() {
      _importing = true;
      _importProgress = 0.0;
    });

    _addLog('🚀 START: Kompletter Neu-Import', type: LogType.warning);

    try {
      final database = await _db.database;

      // SCHRITT 1: DATENBANK LEEREN
      _updateProgress(0.1, 'Lösche alte Daten...');
      await database.delete('ziehungen');
      _addLog('✅ Alte Daten gelöscht', type: LogType.success);

      // SCHRITT 2: IMPORT AUS TXT-DATEIEN STARTEN
      _updateProgress(0.2, 'Importiere Lotto 6aus49...');
      
      // Hier müsste der echte Import-Code hin
      // Da wir den Import aus den TXT-Dateien brauchen, aber wir haben
      // keine direkte Import-Methode in der Datenbank-Klasse
      
      // Stattdessen: Aufruf der Datenbank-Initialisierung neu triggern
      // Dazu brauchen wir Zugriff auf die Import-Logik
      
      _addLog('⚠️  IMPORT-LOGIK FEHLT - Datenbank ist jetzt LEER!', type: LogType.warning);
      _addLog('ℹ️  Bitte implementiere echten Import nach dem Löschen', type: LogType.info);

      // Fake-Fortschritt (wie vorher)
      for (int i = 4; i <= 9; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        _updateProgress(i / 10.0, 'Simulierter Import...');
      }

      await Future.delayed(const Duration(seconds: 1));
      _updateProgress(1.0, 'Import simuliert');
      
      _addLog('⚠️  DATENBANK IST LEER - Keine echten Daten importiert!', type: LogType.error);
      _addLog('ℹ️  App-Neustart lädt Daten aus TXT neu', type: LogType.info);

      await _loadStats();

    } catch (e) {
      _addLog('❌ IMPORT FEHLGESCHLAGEN: \$e', type: LogType.error);
    } finally {
      setState(() => _importing = false);
    }
  }
CORRECTED

# Zeige die korrigierte Version
echo ""
echo "📋 KORRIGIERTE _triggerReimport METHODE:"
echo "========================================"
cat /tmp/corrected_reimport.txt
echo ""
echo "⚠️  WICHTIG: Die Methode zeigt jetzt deutlich, dass die Import-Logik fehlt!"
echo "   Aktuell wird nur gelöscht, nicht neu importiert."
echo ""
echo "🔧 Lösung: Wir müssen die echte Import-Logik aus lotto_database.dart hier aufrufen."
