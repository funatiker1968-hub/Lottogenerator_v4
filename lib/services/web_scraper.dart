import 'package:http/http.dart' as http;
import '../models/lotto_data.dart';
import 'lotto_database.dart';
import 'winnersystem_parser.dart';

class WinnersystemScraper {
  final String baseUrl = 'https://winnersystem.org/archiv/';
  bool isBlocked = false;
  String lastError = '';
  int _importCounter = 0;

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
      
      // 3. Verwende speziellen Parser für winnersystem.org Format
      final ziehungen = WinnersystemParser.parseSimple(response.body);
      
      // 4. In Datenbank speichern
      if (ziehungen.isNotEmpty) {
        for (var ziehung in ziehungen) {
          await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
          await Future.delayed(const Duration(milliseconds: 50));
        }
        
        result.success = true;
        result.importedCount = ziehungen.length;
        result.message = 'Erfolgreich ${ziehungen.length} Ziehungen importiert';
        
        print('✅ Import erfolgreich: ${ziehungen.length} Ziehungen');
      } else {
        result.success = false;
        result.errorMessage = 'Keine Ziehungen im HTML gefunden';
        result.suggestion = 'Versuchen Sie die manuelle Text-Eingabe';
      }
      
    } catch (e) {
      result.success = false;
      result.errorMessage = 'Exception: $e';
      print('❌ Import fehlgeschlagen: $e');
    }
    
    return result;
  }
  
  // NEU: Import für kopierte Tabellendaten von winnersystem.org
  Future<ScraperResult> importWinnersystemTable(String rawText) async {
    final result = ScraperResult();
    
    try {
      print('📊 Starte Winnersystem.org Tabellen-Parsing...');
      
      // Verwende den speziellen Parser für Tabellendaten
      final ziehungen = WinnersystemParser.parseTabellenDaten(rawText);
      
      if (ziehungen.isEmpty) {
        // Fallback: Versuche einfacheres Parsing
        print('🔄 Versuche alternative Parsing-Methode...');
        final ziehungen2 = WinnersystemParser.parseSimple(rawText);
        
        if (ziehungen2.isNotEmpty) {
          for (var ziehung in ziehungen2) {
            await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
          }
          
          result.success = true;
          result.importedCount = ziehungen2.length;
          result.message = 'Erfolgreich ${ziehungen2.length} Ziehungen importiert (alternative Methode)';
        } else {
          result.success = false;
          result.errorMessage = 'Konnte keine Lottozahlen im Text finden';
          result.suggestion = 'Bitte kopieren Sie nur die Lottozahlen ohne Gewinnklassen';
        }
      } else {
        // Speichere gefundene Ziehungen
        for (var ziehung in ziehungen) {
          await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
        }
        
        result.success = true;
        result.importedCount = ziehungen.length;
        result.message = 'Erfolgreich ${ziehungen.length} Ziehungen importiert';
      }
      
    } catch (e) {
      result.success = false;
      result.errorMessage = 'Fehler beim Tabellen-Import: $e';
      print('❌ Tabellen-Import fehlgeschlagen: $e');
    }
    
    return result;
  }
  
  // Alternative: Manuellen Import über CSV-ähnlichen Text
  Future<ScraperResult> importFromText(String rawText, String spieltyp) async {
    final result = ScraperResult();
    
    try {
      print('📝 Starte Text-Import...');
      
      // Zuerst versuchen wir den speziellen Tabellen-Parser
      final tableResult = await importWinnersystemTable(rawText);
      
      if (tableResult.success) {
        return tableResult;
      } else {
        // Fallback: Einfaches Text-Parsing
        final ziehungen = <LottoZiehung>[];
        _importCounter = 0;
        
        final lines = rawText.split('\n');
        
        for (var line in lines) {
          if (line.trim().isEmpty) continue;
          
          final ziehung = _parseTextLine(line, spieltyp);
          if (ziehung != null) {
            ziehungen.add(ziehung);
          }
        }
        
        if (ziehungen.isNotEmpty) {
          for (var ziehung in ziehungen) {
            await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
          }
          
          result.success = true;
          result.importedCount = ziehungen.length;
          result.message = 'Erfolgreich ${ziehungen.length} Ziehungen importiert';
        } else {
          result.success = false;
          result.errorMessage = 'Konnte keine Daten aus dem Text extrahieren';
          result.suggestion = 'Bitte verwenden Sie das Format: "01.02.2023 3 7 12 25 34 42 SZ:8"';
        }
      }
      
    } catch (e) {
      result.success = false;
      result.errorMessage = 'Fehler beim Text-Import: $e';
    }
    
    return result;
  }
  
  // URL für verschiedene Lotto-Typen erstellen
  String _buildUrl(String spieltyp, int jahr) {
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
  
  // Einfaches Text-Parsing (Fallback)
  LottoZiehung? _parseTextLine(String line, String spieltyp) {
    try {
      // Einfaches Format: "01.02.2023 3 7 12 25 34 42"
      final zahlMatches = RegExp(r'\b\d{1,2}\b').allMatches(line);
      final allNumbers = zahlMatches.map((m) {
        try {
          return int.parse(m.group(0)!);
        } catch (e) {
          return -1;
        }
      }).where((n) => n > 0 && n <= 49).toList();
      
      if (allNumbers.length >= 6) {
        _importCounter++;
        
        // Erste 6 Zahlen verwenden
        final zahlen = allNumbers.sublist(0, 6);
        
        return LottoZiehung(
          datum: DateTime.now().subtract(Duration(days: _importCounter * 7)),
          zahlen: zahlen,
          superzahl: 0,
          spieltyp: spieltyp,
        );
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
