import '../models/lotto_data.dart';

class WinnersystemParser {
  
  // Parsen der kopierten Tabellendaten von winnersystem.org
  static List<LottoZiehung> parseTabellenDaten(String rawText) {
    final ziehungen = <LottoZiehung>[];
    final lines = rawText.split('\n');
    
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      final ziehung = _parseTabellenZeile(line);
      if (ziehung != null) {
        ziehungen.add(ziehung);
        print('✅ Parsed: ${ziehung.formatierterDatum} ${ziehung.zahlen.join(',')}');
      }
    }
    
    return ziehungen;
  }
  
  static LottoZiehung? _parseTabellenZeile(String line) {
    try {
      print('📝 Parse Zeile: $line');
      
      // Das Format ist: DATUM + Lottozahlen + Gewinnklassen + Beträge
      // Beispiel: "03.12.2025￼212729374449619855310.701465725.2019543.007497.90247.4070.9025.3013.90"
      
      // 1. Finde das Datum (immer am Anfang)
      final datumMatch = RegExp(r'^(\d{1,2}\.\d{1,2}\.\d{4})').firstMatch(line);
      if (datumMatch == null) {
        print('❌ Kein Datum gefunden');
        return null;
      }
      
      final datumText = datumMatch.group(1)!;
      print('📅 Datum: $datumText');
      
      // 2. Parse Datum
      final dateParts = datumText.split('.');
      final tag = int.parse(dateParts[0]);
      final monat = int.parse(dateParts[1]);
      final jahr = int.parse(dateParts[2]);
      final datum = DateTime(jahr, monat, tag);
      
      // 3. Finde die Lottozahlen (6 Zahlen nach dem Datum)
      // Nach dem Datum kommen 6 zweistellige Zahlen
      final restDerZeile = line.substring(datumText.length);
      
      // Entferne Sonderzeichen (wie ￼)
      final cleanRest = restDerZeile.replaceAll(RegExp(r'[^\d\.]'), '');
      
      // Finde alle Zahlen im Rest
      final zahlMatches = RegExp(r'\d{1,2}').allMatches(cleanRest);
      final allNumbers = zahlMatches.map((m) => int.parse(m.group(0)!)).toList();
      
      print('🔢 Alle Zahlen: $allNumbers');
      
      if (allNumbers.length >= 6) {
        // Die ersten 6 Zahlen nach dem Datum sind die Lottozahlen
        final lottozahlen = allNumbers.sublist(0, 6);
        
        // Prüfe ob Zahlen im gültigen Bereich (1-49)
        final validZahlen = lottozahlen.where((n) => n >= 1 && n <= 49).toList();
        
        if (validZahlen.length == 6) {
          // Superzahl ist normalerweise die 7. Zahl
          final superzahl = allNumbers.length > 6 ? allNumbers[6] : 0;
          
          return LottoZiehung(
            datum: datum,
            zahlen: validZahlen,
            superzahl: superzahl,
            spieltyp: '6aus49',
          );
        } else {
          print('⚠️ Ungültige Lottozahlen: $lottozahlen');
        }
      } else {
        print('⚠️ Nicht genug Zahlen gefunden: ${allNumbers.length}');
      }
      
    } catch (e) {
      print('❌ Fehler beim Parsen: $e');
    }
    
    return null;
  }
  
  // Alternative: Einfacheres Parsing für reine Lottozahlen
  static List<LottoZiehung> parseReineLottozahlen(String rawText) {
    final ziehungen = <LottoZiehung>[];
    final lines = rawText.split('\n');
    int counter = 0;
    
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Suche nach Datum + 6 Zahlen Muster
      final matches = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4}).*?(\d{1,2})\D+?(\d{1,2})\D+?(\d{1,2})\D+?(\d{1,2})\D+?(\d{1,2})\D+?(\d{1,2})').allMatches(line);
      
      for (var match in matches) {
        try {
          // Datum
          final datumText = match.group(1)!;
          final dateParts = datumText.split('.');
          final tag = int.parse(dateParts[0]);
          final monat = int.parse(dateParts[1]);
          final jahr = int.parse(dateParts[2]);
          
          // Zahlen
          final zahlen = [
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
            int.parse(match.group(4)!),
            int.parse(match.group(5)!),
            int.parse(match.group(6)!),
            int.parse(match.group(7)!),
          ];
          
          // Validiere
          final validZahlen = zahlen.where((n) => n >= 1 && n <= 49).toList();
          
          if (validZahlen.length == 6) {
            counter++;
            final datum = DateTime(jahr, monat, tag);
            
            ziehungen.add(LottoZiehung(
              datum: datum,
              zahlen: validZahlen,
              superzahl: 0, // Superzahl separat extrahieren
              spieltyp: '6aus49',
            ));
            
            print('✅ Found: $datumText ${validZahlen.join(',')}');
          }
        } catch (e) {
          print('⚠️ Match parsing failed: $e');
        }
      }
    }
    
    print('📊 Total parsed: ${ziehungen.length} ziehungen');
    return ziehungen;
  }
  
  // Einfachste Methode: Extrahiere nur die 6 Lottozahlen nach jedem Datum
  static List<LottoZiehung> parseSimple(String rawText) {
    final ziehungen = <LottoZiehung>[];
    int currentYear = DateTime.now().year;
    int ziehungsCounter = 0;
    
    // Ersetze alle nicht-numerischen Zeichen außer Punkten
    String cleanText = rawText.replaceAll(RegExp(r'[^\d\.\s]'), ' ');
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ');
    
    print('🧹 Cleaned text: ${cleanText.substring(0, 100)}...');
    
    // Finde alle Daten
    final datumMatches = RegExp(r'\d{1,2}\.\d{1,2}\.\d{4}').allMatches(cleanText);
    final daten = datumMatches.map((m) => m.group(0)!).toList();
    
    print('📅 Found ${daten.length} dates');
    
    for (var datumText in daten) {
      try {
        // Finde Position dieses Datums im Text
        final startIndex = cleanText.indexOf(datumText);
        if (startIndex == -1) continue;
        
        // Extrahiere Text nach dem Datum (nächsten 100 Zeichen)
        final textAfterDate = cleanText.substring(startIndex + datumText.length, 
            startIndex + datumText.length + 100);
        
        // Finde 6 Zahlen nach dem Datum
        final zahlMatches = RegExp(r'\b(\d{1,2})\b').allMatches(textAfterDate);
        final numbers = zahlMatches.take(6).map((m) => int.parse(m.group(1)!)).toList();
        
        if (numbers.length == 6) {
          // Validiere Zahlen
          final validNumbers = numbers.where((n) => n >= 1 && n <= 49).toList();
          
          if (validNumbers.length == 6) {
            // Parse Datum
            final dateParts = datumText.split('.');
            final tag = int.parse(dateParts[0]);
            final monat = int.parse(dateParts[1]);
            var jahr = int.parse(dateParts[2]);
            
            ziehungsCounter++;
            
            final ziehung = LottoZiehung(
              datum: DateTime(jahr, monat, tag),
              zahlen: validNumbers,
              superzahl: 0,
              spieltyp: '6aus49',
            );
            
            ziehungen.add(ziehung);
            print('✅ $datumText: ${validNumbers.join(',')}');
          }
        }
      } catch (e) {
        print('⚠️ Error parsing $datumText: $e');
      }
    }
    
    return ziehungen;
  }
}
