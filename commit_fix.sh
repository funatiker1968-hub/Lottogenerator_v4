#!/bin/bash

echo "📦 Bereite Commit vor..."

git add lib/screens/database_status_screen.dart

echo "💾 Erstelle Commit..."
git commit -m "FIX: 'KOMPLETTEN IMPORT STARTEN'-Button löscht UND füllt DB korrekt

- PROBLEM: _triggerReimport() löschte nur Datenbank, importierte aber nicht neu
- LÖSUNG: Vollständiger Neu-Import aus TXT-Dateien implementiert

- KORRIGIERTE LOGIK in _triggerReimport():
  1. 🗑️  Löscht alle Einträge aus 'ziehungen'-Tabelle
  2. 📥 Importiert Lotto 6aus49 aus assets/data/lotto_1955_2025.txt
     * Format: dd.mm.yyyy | z1 z2 z3 z4 z5 z6 | sz
     * Konvertiert Datum zu: dd-mm-yyyy
     * Importiert ~5894 Einträge (1955-2025)
     * Echter Fortschrittsbalken: 20% → 60%
  
  3. 📥 Importiert Eurojackpot aus assets/data/eurojackpot_2012_2025.txt
     * Format: yyyy-mm-dd | h1 h2 h3 h4 h5 | e1 e2
     * Kombiniert Haupt- + Eurozahlen zu einem String
     * Importiert ~600+ Einträge (2012-2025)
     * Echter Fortschrittsbalken: 65% → 95%
  
  4. 🎉 Abschluss und Statistik-Aktualisierung
     * Fortschritt: 100%
     * Erfolgsmeldungen im Log
     * _loadStats() wird aufgerufen

- DETAILLIERTE LOG-AUSGABEN:
  * Jeder Schritt wird protokolliert (Löschen, Lotto-Import, Eurojackpot-Import)
  * Fehler werden separat pro Import erfasst
  * Erfolgreiche Imports zeigen Anzahl der importierten Einträge
  * Abschlussmeldung mit Gesamtergebnis

- ECHTER FORTSCHRITTSBALKEN:
  * 0-10%: Datenbank leeren
  * 10-60%: Lotto 6aus49 importieren (~5894 Einträge)
  * 60-95%: Eurojackpot importieren (~600 Einträge)
  * 95-100%: Abschluss & Statistik aktualisieren

- FEHLERBEHANDLUNG:
  * Try-Catch für jeden Import-Schritt separat
  * Falls ein Import fehlschlägt, wird der andere trotzdem versucht
  * Fehlermeldungen erscheinen im Terminal-Log

DER BUTTON FUNKTIONIERT JETZT WIE ERWARTET:
✅ Löscht komplette Datenbank
✅ Importiert Lotto-Daten neu aus TXT
✅ Importiert Eurojackpot-Daten neu aus TXT
✅ Zeigt echten Fortschritt basierend auf importierten Datensätzen
✅ Aktualisiert Statistik nach erfolgreichem Import"
