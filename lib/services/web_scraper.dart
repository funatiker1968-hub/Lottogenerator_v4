import 'package:http/http.dart' as http;
import '../models/lotto_data.dart';
import 'lotto_database.dart';
import 'winnersystem_parser.dart';

class WinnersystemScraper {
  final String baseUrl = 'https://winnersystem.org/archiv/';
  bool isBlocked = false;
  String lastError = '';
  int _importCounter = 0;

  // NEU: Alternative Datenquellen
  final Map<String, String> alternativeSources = {
    'lottozahlen': 'https://www.lottozahlenonline.de/lotto/6aus49/archiv/',
    'lottoarchiv': 'https://www.lottoarchiv.de/lotto/6aus49/',
  };

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
        result.suggestion = 'Bitte manuell über Text importieren oder alternative Quelle verwenden';
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
  
  // NEU: Import von alternativer Quelle
  Future<ScraperResult> importFromAlternativeSource(String source, int jahr) async {
    print('🔄 Versuche alternative Quelle: $source für Jahr $jahr');
    
    final result = ScraperResult();
    
    try {
      String url;
      
      switch (source) {
        case 'lottozahlen':
          url = 'https://www.lottozahlenonline.de/lotto/6aus49/archiv/$jahr.html';
          break;
        default:
          url = 'https://www.lottoarchiv.de/lotto/6aus49/$jahr/';
      }
      
      print('📡 Lade alternative URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        // Versuche verschiedene Parsing-Methoden
        final ziehungen = _parseAlternativeSource(response.body, jahr);
        
        if (ziehungen.isNotEmpty) {
          for (var ziehung in ziehungen) {
            await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
          }
          
          result.success = true;
          result.importedCount = ziehungen.length;
          result.message = 'Erfolgreich ${ziehungen.length} Ziehungen von $source importiert';
        } else {
          result.success = false;
          result.errorMessage = 'Konnte keine Daten von $source extrahieren';
          result.suggestion = 'Bitte manuell über Text importieren';
        }
      } else {
        result.success = false;
        result.errorMessage = 'Alternative Quelle nicht erreichbar (${response.statusCode})';
      }
      
    } catch (e) {
      result.success = false;
      result.errorMessage = 'Fehler mit alternativer Quelle: $e';
    }
    
    return result;
  }
  
  // NEU: Import von eigener URL
  Future<ScraperResult> importFromCustomUrl(String url, int jahr) async {
    print('🔄 Import von eigener URL: $url');
    
    final result = ScraperResult();
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        // Versuche zu parsen
        final ziehungen = _parseGenericHtml(response.body, jahr);
        
        if (ziehungen.isNotEmpty) {
          for (var ziehung in ziehungen) {
            await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
          }
          
          result.success = true;
          result.importedCount = ziehungen.length;
          result.message = 'Erfolgreich ${ziehungen.length} Ziehungen importiert';
        } else {
          // Falls Parsing fehlschlägt, zeige den HTML-Code für manuelles Kopieren
          result.success = false;
          result.errorMessage = 'Automatisches Parsing fehlgeschlagen';
          result.suggestion = 'Bitte kopieren Sie die Lottozahlen manuell aus der Seite';
          
          // Debug: Zeige ersten 500 Zeichen des HTML
          print('📄 HTML-Vorschau: ${response.body.substring(0, 500)}...');
        }
      } else {
        result.success = false;
        result.errorMessage = 'URL nicht erreichbar (${response.statusCode})';
      }
      
    } catch (e) {
      result.success = false;
      result.errorMessage = 'Fehler beim Zugriff auf URL: $e';
    }
    
    return result;
  }
  
  // NEU: Generischer HTML-Parser für verschiedene Quellen
  List<LottoZiehung> _parseGenericHtml(String html, int jahr) {
    final ziehungen = <LottoZiehung>[];
    
    try {
      // Methode 1: Suche nach Tabellen mit Lottozahlen
      final tableRegex = RegExp(r'<table[^>]*>.*?(\d{1,2}\.\d{1,2}\.\d{4}).*?(\d{1,2}).*?(\d{1,2}).*?(\d{1,2}).*?(\d{1,2}).*?(\d{1,2}).*?(\d{1,2})', 
        caseSensitive: false, dotAll: true);
      
      final matches = tableRegex.allMatches(html);
      
      for (var match in matches) {
        try {
          final dateParts = match.group(1)!.split('.');
          final zahlen = [
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
            int.parse(match.group(4)!),
            int.parse(match.group(5)!),
            int.parse(match.group(6)!),
            int.parse(match.group(7)!),
          ];
          
          // Validiere
          if (zahlen.every((n) => n >= 1 && n <= 49)) {
            final ziehung = LottoZiehung(
              datum: DateTime(
                int.parse(dateParts[2]),
                int.parse(dateParts[1]),
                int.parse(dateParts[0]),
              ),
              zahlen: zahlen,
              superzahl: 0,
              spieltyp: '6aus49',
            );
            
            ziehungen.add(ziehung);
            print('✅ Gefunden: ${ziehung.formatierterDatum} ${zahlen.join(',')}');
          }
        } catch (e) {
          // Nächsten Versuch
        }
      }
      
      // Methode 2: Falls Tabelle nicht gefunden, suche nach einfachen Zahlenmustern
      if (ziehungen.isEmpty) {
        return WinnersystemParser.parseSimple(html);
      }
      
    } catch (e) {
      print('⚠️ Generisches Parsing fehlgeschlagen: $e');
    }
    
    return ziehungen;
  }
  
  // NEU: Parser für alternative Quellen
  List<LottoZiehung> _parseAlternativeSource(String html, int jahr) {
    final ziehungen = <LottoZiehung>[];
    
    // Versuche erst generisches Parsing
    ziehungen.addAll(_parseGenericHtml(html, jahr));
    
    // Falls nichts gefunden, versuche spezifische Muster
    if (ziehungen.isEmpty) {
      // Suche nach div-Klassen die Lottozahlen enthalten könnten
      final numberDivs = RegExp(r'<div[^>]*class="[^"]*lotto[^"]*"[^>]*>.*?(\d{1,2}).*?(\d{1,2}).*?(\d{1,2}).*?(\d{1,2}).*?(\d{1,2}).*?(\d{1,2})',
        caseSensitive: false, dotAll: true).allMatches(html);
      
      int counter = 0;
      for (var match in numberDivs) {
        try {
          final zahlen = [
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
            int.parse(match.group(4)!),
            int.parse(match.group(5)!),
            int.parse(match.group(6)!),
          ];
          
          if (zahlen.every((n) => n >= 1 && n <= 49)) {
            counter++;
            ziehungen.add(LottoZiehung(
              datum: DateTime(jahr, 1, 1).add(Duration(days: counter * 7)),
              zahlen: zahlen,
              superzahl: 0,
              spieltyp: '6aus49',
            ));
          }
        } catch (e) {
          // Weiter
        }
      }
    }
    
    return ziehungen;
  }
  
  // [Rest des Codes bleibt gleich wie vorher...]
  
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
          result.suggestion = 'Bitte verwenden Sie das Format: "01.02.2023 3 7 12 25 34 42"';
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
      'Access denied',
      'Security check',
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
        
        // Versuche Datum zu extrahieren
        DateTime? datum;
        final dateMatch = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(line);
        if (dateMatch != null) {
          datum = DateTime(
            int.parse(dateMatch.group(3)!),
            int.parse(dateMatch.group(2)!),
            int.parse(dateMatch.group(1)!),
          );
        } else {
          // Fallback: Künstliches Datum
          datum = DateTime.now().subtract(Duration(days: _importCounter * 7));
        }
        
        // Erste 6 Zahlen verwenden
        final zahlen = allNumbers.sublist(0, 6);
        
        return LottoZiehung(
          datum: datum,
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
