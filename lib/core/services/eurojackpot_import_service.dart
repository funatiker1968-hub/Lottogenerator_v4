import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'eurojackpot_db_service.dart';

class EurojackpotImportService {
  EurojackpotImportService._();
  static final EurojackpotImportService instance = EurojackpotImportService._();

  static const _assetPath = 'assets/data/eurojackpot_2012_2025.txt';

  Future<int> importIfEmpty() async {
    final db = EurojackpotDbService.instance;
    final existing = await db.countDraws();
    if (existing > 0) return 0;

    final raw = await rootBundle.loadString(_assetPath);
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.startsWith('#'))
        .toList();

    int inserted = 0;

    for (final line in lines) {
      // Erwartet: YYYY-MM-DD | n1 n2 n3 n4 n5 | e1 e2
      final parts = line.split('|').map((e) => e.trim()).toList();
      if (parts.length != 3) {
        // NICHT erfinden -> überspringen
        continue;
      }

      final date = parts[0];
      final mainNums = parts[1].split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      final euroNums = parts[2].split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

      if (mainNums.length != 5 || euroNums.length != 2) {
        continue;
      }

      final n = mainNums.map(int.tryParse).toList();
      final e = euroNums.map(int.tryParse).toList();

      if (n.any((x) => x == null) || e.any((x) => x == null)) {
        continue;
      }

      await db.upsertDraw(
        drawDate: date,
        n1: n[0]!, n2: n[1]!, n3: n[2]!, n4: n[3]!, n5: n[4]!,
        e1: e[0]!, e2: e[1]!,
      );
      inserted++;
    }

    return inserted;
  }
}
