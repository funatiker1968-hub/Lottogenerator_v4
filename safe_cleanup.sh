#!/bin/bash
# safe_cleanup.sh — verschiebt alle Dateien/Ordner mit typischen „Backup“- oder „Sound“-Muster
# in ein neues Backup-Verzeichnis, statt sie endgültig zu löschen.

# === Konfiguration ===
BACKUP_DIR="$HOME/lottogenerator_unused_backup_$(date +%Y%m%d_%H%M%S)"
echo "Erstelle Backup-Ordner: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# === Verschiebe-Dateien ===
# Kriterien: name enthält "sound" oder "backup" oder Endung *.bak (anpassbar)
echo "Verschiebe Dateien mit Mustern: *sound*, *backup*, *.bak  …"
find . -type f \( -iname '*sound*' -o -iname '*backup*' -o -iname '*.bak' \) -print0 | \
  xargs -0 -I{} mv -v "{}" "$BACKUP_DIR"/

echo "✅ Verschiebe-Schritt abgeschlossen."
echo "Alle gefundenen Dateien befinden sich in: $BACKUP_DIR"
echo "Bitte überprüfe das Projekt jetzt mit 'flutter analyze' und ggf. 'flutter build'."
