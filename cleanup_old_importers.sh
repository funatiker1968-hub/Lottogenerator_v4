#!/bin/bash

# Liste alter Dateien:
FILES=(
  "lib/services/multi_lotto_importer.dart"
  "lib/services/lotto_api_importer.dart"
  "lib/services/lotto_6aus49_importer.dart"
  "lib/services/lotto_euro_importer.dart"
  "lib/services/eurojackpot_importer.dart"
  "lib/services/lotto_import_safe.dart"
  "lib/services/web_scraper.dart"
)

echo "Lösche alte Importer & Scraper ..."

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    git rm "$file"
    echo "Entfernt: $file"
  else
    echo "Nicht gefunden: $file"
  fi
done

echo "Fertig. Jetzt committen!"
