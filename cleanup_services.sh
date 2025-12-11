#!/bin/bash
set -e

echo "📦 Backup alter Services → backup_old_services_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf backup_old_services_$(date +%Y%m%d_%H%M%S).tar.gz \
  lib/services/eurojackpot_importer.dart \
  lib/services/lotto_6aus49_importer.dart \
  lib/services/lotto_importer.dart \
  lib/services/web_scraper.dart \
  lib/services/multi_lotto_importer.dart \
  lib/services/auto_import_service.dart \
  lib/services/lotto_import_safe.dart 2>/dev/null || true

echo "🗑 Lösche alte Dateien…"
rm -f lib/services/eurojackpot_importer.dart
rm -f lib/services/lotto_6aus49_importer.dart
rm -f lib/services/lotto_importer.dart
rm -f lib/services/web_scraper.dart
rm -f lib/services/multi_lotto_importer.dart
rm -f lib/services/auto_import_service.dart
rm -f lib/services/lotto_import_safe.dart

echo "✔ Git Commit"
git add -A
git commit -m "Cleanup: remove old scrapers & unused import services"

echo "Fertig."
