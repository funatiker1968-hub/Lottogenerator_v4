#!/bin/bash

echo "🔄 Setze database_status_screen.dart zurück..."

# 1. Backup der kaputten Datei
cp lib/screens/database_status_screen.dart lib/screens/database_status_screen.dart.BROKEN

# 2. Zurück zum letzten funktionierenden Commit
git checkout HEAD -- lib/screens/database_status_screen.dart

echo "✅ Datei zurückgesetzt auf funktionierende Version."
echo ""
echo "🔍 Jetzt zeige ich die ORIGINALE _triggerReimport Methode..."
