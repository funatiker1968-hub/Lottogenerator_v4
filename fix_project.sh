#!/usr/bin/env bash

# --- Remove sound dependencies & imports ---
# (we just delete or comment out files that rely on audioplayers)

SOUND_FILES=(
  "lib/core/lg_sounds.dart"
  "lib/screens/home_screen.dart"
  "lib/screens/home_screen_BACKUP_20251207_0222.dart"
  "lib/widgets/historie_button.dart"
  "lib/widgets/statistik_button.dart"
  "lib/screens/lotto6/backup_junk/lg_sounds.dart"
  "lib/screens/lotto6/core_sounds.dart"
)

echo "Removing sound-related files..."
for f in "\${SOUND_FILES[@]}"; do
  if [ -f "\$f" ]; then
    rm "\$f"
    echo "  Removed \$f"
  fi
done

# --- Replace HTML-Scraper with working version using package:html ---
cat << 'SCRAPER' > lib/services/lotto_online_import.dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/lotto_data_erweitert.dart';
import 'lotto_database_erweitert.dart';

class LottoOnlineImport {
  static const String _baseUrl = 'https://www.lottozahlenonline.de/statistik/beide-spieltage/lottozahlen-archiv.php';

  /// Importiert Ziehungen von startJahr bis endJahr (inklusive)
  static Future<int> importRange(int startJahr, int endJahr) async {
    int totalInserted = 0;
    for (int jahr = startJahr; jahr <= endJahr; jahr++) {
      totalInserted += await importJahr(jahr);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return totalInserted;
  }

  static Future<int> importJahr(int jahr) async {
    final uri = Uri.parse('$_baseUrl?j=$jahr#lottozahlen-archiv');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      print('HTTP error \${res.statusCode} for year \$jahr');
      return 0;
    }
    final doc = html_parser.parse(res.body);
    final table = doc.querySelector('table');
    if (table == null) {
      print('No table found for year \$jahr');
      return 0;
    }
    final rows = table.querySelectorAll('tr').skip(1);
    List<LottoZiehung> entries = [];

    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 10) continue;
      final dateStr = cells[1].text.trim(); // e.g. "01.01.2025"
      List<int> nums = [];
      for (int i = 3; i < 9; i++) {
        final n = int.tryParse(cells[i].text.trim());
        if (n == null) { nums.clear(); break; }
        nums.add(n);
      }
      if (nums.length != 6) continue;
      final superStr = cells[9].text.trim();
      final sz = int.tryParse(superStr);
      if (sz == null) continue;
      final parts = dateStr.split('.');
      if (parts.length != 3) continue;
      final datum = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      entries.add(LottoZiehung(
        datum: datum,
        zahlen: nums,
        superzahl: sz,
        spieltyp: '6aus49',
      ));
    }

    final inserted = await ErweiterteLottoDatenbank.fuegeZiehungenHinzu(entries);
    print('Year \$jahr → inserted: \$inserted');
    return inserted;
  }
}
SCRAPER

echo "Created new HTML-importer: lib/services/lotto_online_import.dart"

# --- Update pubspec.yaml to ensure html and http dependencies are present, remove audioplayers if present ---
cat << 'EOF2' > pubspec.yaml
name: lottogenerator_v4
description: Lotto Generator V4 mit Historie & Import
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0
  html: ^0.15.0
  sqflite: ^2.4.2
  path: ^1.8.0
  cupertino_icons: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
EOF2

echo "pubspec.yaml overwritten (sound removed, html/http restored)"

# --- Clean and get packages ---
flutter clean
flutter pub get

echo "Cleanup and package install done. Jetzt flutter analyze ausführen."

