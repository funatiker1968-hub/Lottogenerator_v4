import 'package:http/http.dart' as http;
import '../models/lotto_data.dart';
import 'lotto_database.dart';

class WinnersystemScraper {
  final String baseUrl = 'https://winnersystem.org/archiv/';
  bool isBlocked = false;
  String lastError = '';
  int _importCounter = 0; // Für Datum-Generierung

  // Hauptfunktion: Importiere ein bestimmtes Jahr
  Future<ScraperResult> importYear(String spieltyp, int jahr) async {
    print('🔄 Starte Import für $spieltyp Jahr $jahr...');
    
    final result = ScraperResult();
    
    try {
      // 1. HTML-Seite abrufen
      final url = _buildUrl(spieltyp, jahr);
      print('📡 Lade URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
      
      // 2. Prüfen auf Blockierung
      if (_checkIfBlocked(response.body)) {
        isBlocked = true;
        lastError = 'Website hat den Zugriff blockiert (Cloudflare Protection)';
        result.success = false;
        result.errorMessage = lastError;
        result.suggestion = 'Bitte manuell über CSV importieren';
        return result;
      }
      
      if (response.statusCode != 200) {
        result.success = false;
        result.errorMessage = 'HTTP Fehler ${response.statusCode}';
        return result;
      }
      
      // 3. HTML als Text verarbeiten (einfache Methode ohne html-Parser)
      final ziehungen = _parseHtmlAsText(response.body, spieltyp, jahr);
      
      // 4. In Datenbank speichern
      if (ziehungen.isNotEmpty) {
        for (var ziehung in ziehungen) {
          await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
          await Future.delayed(const Duration(milliseconds: 50)); // Respektvolle Pause
        }
        
        result.success = true;
        result.importedCount = ziehungen.length;
        result.message = 'Erfolgreich ${ziehungen.length} Ziehungen importiert';
        
        print('✅ Import erfolgreich: ${ziehungen.length} Ziehungen');
      } else {
        result.success = false;
        result.errorMessage = 'Keine Ziehungen im HTML gefunden';
        result.suggestion = 'Die Seitenstruktur hat sich geändert oder ist unbekannt';
      }
      
    } catch (e) {
      result.success = false;
      result.errorMessage = 'Exception: $e';
      print('❌ Import fehlgeschlagen: $e');
    }
    
    return result;
  }
  
  // Alternative: Manuellen Import über CSV-ähnlichen Text
  Future<ScraperResult> importFromText(String rawText, String spieltyp) async {
    final result = ScraperResult();
    final ziehungen = <LottoZiehung>[];
    _importCounter = 0; // Reset counter
    
    try {
      // Einfaches Text-Parsing für manuell kopierte Daten
      final lines = rawText.split('\n');
      
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        
        final ziehung = _parseTextLine(line, spieltyp);
        if (ziehung != null) {
          ziehungen.add(ziehung);
        }
      }
      
      // In Datenbank speichern
      if (ziehungen.isNotEmpty) {
        for (var ziehung in ziehungen) {
          await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
        }
        
        result.success = true;
        result.importedCount = ziehungen.length;
        result.message = 'Erfolgreich ${ziehungen.length} Ziehungen aus Text importiert';
      } else {
        result.success = false;
        result.errorMessage = 'Konnte keine Daten aus dem Text extrahieren';
      }
      
    } catch (e) {
      result.success = false;
      result.errorMessage = 'Fehler beim Text-Import: $e';
    }
    
    return result;
  }
  
  // URL für verschiedene Lotto-Typen erstellen
  String _buildUrl(String spieltyp, int jahr) {
    // Basierend auf typischen winnersystem.org URLs
    switch (spieltyp) {
      case '6aus49':
        return '$baseUrl/lottozahlen/lottozahlen-$jahr.html';
      case 'Eurojackpot':
        return '$baseUrl/eurojackpot/eurojackpot-$jahr.html';
      default:
        return '$baseUrl$spieltyp/$jahr.html';
    }
  }
  
  // HTTP Headers für bessere Akzeptanz
  Map<String, String> _getHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
    };
  }
  
  // Prüfen ob die Seite blockiert (Cloudflare)
  bool _checkIfBlocked(String html) {
    final blockedIndicators = [
      'Cloudflare',
      'under attack',
      'DDoS protection',
      'Please enable JavaScript',
      'Verifying your browser',
    ];
    
    for (var indicator in blockedIndicators) {
      if (html.toLowerCase().contains(indicator.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
  
  // HTML als Text parsen (einfache Methode)
  List<LottoZiehung> _parseHtmlAsText(String html, String spieltyp, int jahr) {
    final ziehungen = <LottoZiehung>[];
    
    try {
      // Entferne HTML-Tags (grob)
      String cleanText = html
          .replaceAll(RegExp(r'<[^>]*>'), ' ')  // HTML-Tags entfernen
          .replaceAll(RegExp(r'\s+'), ' ')      // Mehrfache Leerzeichen
          .replaceAll('&nbsp;', ' ')            ; // HTML Spaces
      
      // Suche nach Lotto-Ziehungsmustern
      // Muster 1: "01.02.2023 3 7 12 25 34 42"
      // Muster 2: "03.07.12.25.34.42" (Punkte als Trennzeichen)
      // Muster 3: "3,7,12,25,34,42" (Kommas als Trennzeichen)
      
      // Versuche verschiedene RegEx-Muster
      final patterns = [
        // Muster: DD.MM.YYYY gefolgt von 6 Zahlen
        RegExp(r'(\d{1,2}\.\d{1,2}\.\d{2,4})\D+?(\d{1,2})\D+?(\d{1,2})\D+?(\d{1,2})\D+?(\d{1,2})\D+?(\d{1,2})\D+?(\d{1,2})'),
        // Muster: 6 Zahlen mit Punkten
        RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{1,2})\.(\d{1,2})\.(\d{1,2})\.(\d{1,2})'),
        // Muster: 6 Zahlen mit Kommas
        RegExp(r'(\d{1,2}),(\d{1,2}),(\d{1,2}),(\d{1,2}),(\d{1,2}),(\d{1,2})'),
      ];
      
      for (var pattern in patterns) {
        final matches = pattern.allMatches(cleanText);
        
        for (var match in matches) {
          try {
            LottoZiehung? ziehung;
            
            if (pattern == patterns[0]) {
              // Muster mit Datum
              final datumText = match.group(1)!;
              final zahlen = [
                int.parse(match.group(2)!),
                int.parse(match.group(3)!),
                int.parse(match.group(4)!),
                int.parse(match.group(5)!),
                int.parse(match.group(6)!),
                int.parse(match.group(7)!),
              ];
              
              // Datum parsen
              final dateParts = datumText.split('.');
              if (dateParts.length == 3) {
                final tag = int.parse(dateParts[0]);
                final monat = int.parse(dateParts[1]);
                var jahrZ = int.parse(dateParts[2]);
                if (jahrZ < 100) jahrZ += 2000;
                
                final datum = DateTime(jahrZ, monat, tag);
                
                ziehung = LottoZiehung(
                  datum: datum,
                  zahlen: zahlen,
                  superzahl: 0, // Superzahl separat suchen
                  spieltyp: spieltyp,
                );
              }
            } else {
              // Muster ohne Datum - verwende Jahresanfang
              final zahlen = [
                int.parse(match.group(1)!),
                int.parse(match.group(2)!),
                int.parse(match.group(3)!),
                int.parse(match.group(4)!),
                int.parse(match.group(5)!),
                int.parse(match.group(6)!),
              ];
              
              ziehung = LottoZiehung(
                datum: DateTime(jahr, 1, 1),
                zahlen: zahlen,
                superzahl: 0,
                spieltyp: spieltyp,
              );
            }
            
            if (ziehung != null) {
              ziehungen.add(ziehung);
            }
          } catch (e) {
            print('⚠️ Parsing eines Matches fehlgeschlagen: $e');
          }
        }
        
        if (ziehungen.isNotEmpty) {
          break; // Ersten erfolgreichen Parser verwenden
        }
      }
      
      print('🔍 Gefundene Ziehungen im HTML: ${ziehungen.length}');
      
    } catch (e) {
      print('⚠️ HTML-Text-Parsing fehlgeschlagen: $e');
    }
    
    return ziehungen;
  }
  
  // Parsen von manuell eingegebenen Textzeilen
  LottoZiehung? _parseTextLine(String line, String spieltyp) {
    try {
      // Verschiedene Formate unterstützen
      // Format 1: "01.02.2023 3 7 12 25 34 42 SZ:8"
      // Format 2: "2023-02-01: 3,7,12,25,34,42 Superzahl 8"
      // Format 3: "03.07.12.25.34.42" (nur Zahlen)
      
      print('📝 Parse Zeile: $line');
      
      // Extrahiere alle Zahlen
      final zahlMatches = RegExp(r'\b\d{1,2}\b').allMatches(line);
      final allNumbers = zahlMatches.map((m) {
        try {
          return int.parse(m.group(0)!);
        } catch (e) {
          return -1;
        }
      }).where((n) => n > 0 && n <= 49).toList();
      
      print('🔢 Gefundene Zahlen: $allNumbers');
      
      if (allNumbers.length >= 6) {
        DateTime datum;
        List<int> zahlen;
        int superzahl = 0;
        
        // Prüfe ob Datum vorhanden (mind. 7 Zahlen = 3 für Datum + 6 für Lotto)
        if (allNumbers.length >= 9) {
          // Vermutlich mit Datum: erste 3 Zahlen sind Tag.Monat.Jahr
          final tag = allNumbers[0];
          final monat = allNumbers[1];
          var jahr = allNumbers[2];
          if (jahr < 100) jahr += 2000;
          
          datum = DateTime(jahr, monat, tag);
          zahlen = allNumbers.sublist(3, 9); // Nächste 6 Zahlen
          
          // Superzahl könnte die 10. Zahl sein
          if (allNumbers.length >= 10) {
            superzahl = allNumbers[9];
          }
        } else {
          // Ohne Datum - verwende absteigendes Datum basierend auf Zähler
          _importCounter++;
          datum = DateTime.now().subtract(Duration(days: _importCounter * 7));
          zahlen = allNumbers.sublist(0, 6);
        }
        
        // Validiere Zahlen (1-49)
        final validZahlen = zahlen.where((n) => n >= 1 && n <= 49).toList();
        if (validZahlen.length == 6) {
          final ziehung = LottoZiehung(
            datum: datum,
            zahlen: validZahlen,
            superzahl: superzahl,
            spieltyp: spieltyp,
          );
          
          print('✅ Ziehung erstellt: ${ziehung.formatierterDatum} ${validZahlen.join(',')}');
          return ziehung;
        }
      }
    } catch (e) {
      print('⚠️ Textzeilen-Parsing fehlgeschlagen: $e');
    }
    
    return null;
  }
  
  // Test-Funktion: Prüft ob die Website erreichbar ist
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://winnersystem.org/'),
        headers: _getHeaders(),
      );
      
      return !_checkIfBlocked(response.body) && response.statusCode == 200;
    } catch (e) {
      print('❌ Verbindungstest fehlgeschlagen: $e');
      return false;
    }
  }
}

// Ergebnis-Klasse für Scraper-Operationen
class ScraperResult {
  bool success = false;
  int importedCount = 0;
  String message = '';
  String errorMessage = '';
  String suggestion = '';
  
  @override
  String toString() {
    if (success) {
      return '✅ $message (Importiert: $importedCount)';
    } else {
      return '❌ Fehler: $errorMessage${suggestion.isNotEmpty ? "\n💡 $suggestion" : ""}';
    }
  }
}
