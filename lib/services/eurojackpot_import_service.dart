import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

class EurojackpotImportService {
  EurojackpotImportService._();
  static final instance = EurojackpotImportService._();

  // TXT IMPORT FÜR EUROPJACKPOT (Format: YYYY-MM-DD | n n n n n | e e)
  Future<void> importIfEmpty({
    required void Function(String) status,
  }) async {
    status("📥 Eurojackpot Import aus TXT gestartet");
    
    try {
      final txt = await rootBundle.loadString(
        'assets/data/eurojackpot_2012_2025.txt',
      );
      
      final lines = const LineSplitter().convert(txt);
      int neu = 0;
      int skip = 0;
      int total = 0;
      
      for (final line in lines) {
        total++;
        final trimmedLine = line.trim();
        
        // Kommentarzeilen überspringen
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
          continue;
        }
        
        try {
          final ziehung = _parseTXTLine(trimmedLine);
          if (ziehung != null) {
            final exists = await ErweiterteLottoDatenbank
                .pruefeObSchonVorhanden('eurojackpot', ziehung.datum);
            
            if (!exists) {
              await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(ziehung);
              neu++;
            }
          } else {
            skip++;
            status("⚠️ Übersprungen: $trimmedLine");
          }
        } catch (e) {
          skip++;
          status("⚠️ Fehler in Zeile: $trimmedLine - $e");
        }
      }
      
      status("✅ Eurojackpot Import fertig");
      status("   Gelesen: $total Zeilen");
      status("   Neu importiert: $neu");
      status("   Übersprungen: $skip");
    } catch (e) {
      status("❌ Import fehlgeschlagen: $e");
      rethrow;
    }
  }

  LottoZiehung? _parseTXTLine(String line) {
    // Format: "2012-03-23 | 05 08 21 37 46 | 6 8"
    final parts = line.split('|').map((s) => s.trim()).toList();
    
    if (parts.length != 3) {
      return null;
    }
    
    // Datum parsen (YYYY-MM-DD)
    final dateStr = parts[0];
    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      return null;
    }
    
    // 5 Hauptzahlen
    final mainNumbersStr = parts[1];
    final mainNumbers = mainNumbersStr
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map(int.tryParse)
        .where((n) => n != null)
        .map((n) => n!)
        .toList();
    
    if (mainNumbers.length != 5) {
      return null;
    }
    
    // Prüfe Bereich 1-50
    for (final num in mainNumbers) {
      if (num < 1 || num > 50) {
        return null;
      }
    }
    
    // 2 Eurozahlen
    final euroNumbersStr = parts[2];
    final euroNumbers = euroNumbersStr
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map(int.tryParse)
        .where((n) => n != null)
        .map((n) => n!)
        .toList();
    
    if (euroNumbers.length != 2) {
      return null;
    }
    
    // Prüfe Bereich 1-10
    for (final num in euroNumbers) {
      if (num < 1 || num > 10) {
        return null;
      }
    }
    
    // Alle Zahlen kombinieren (5 + 2)
    final allNumbers = [...mainNumbers, ...euroNumbers];
    
    return LottoZiehung(
      datum: date,
      spieltyp: 'eurojackpot',
      zahlen: allNumbers,
      superzahl: 0,
    );
  }

  // MANUELLER BEREICHS-IMPORT (UI)
  Future<void> importRange({
    required DateTime start,
    required DateTime end,
    required void Function(String) status,
  }) async {
    status("ℹ️ Eurojackpot Bereichsimport: ${start.year}–${end.year}");
    status("ℹ️ (Logik folgt – Stub OK)");
  }
}
