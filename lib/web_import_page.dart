import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/web_scraper.dart';

class WebImportPage extends StatefulWidget {
  const WebImportPage({Key? key}) : super(key: key);

  @override
  _WebImportPageState createState() => _WebImportPageState();
}

class _WebImportPageState extends State<WebImportPage> {
  final WinnersystemScraper scraper = WinnersystemScraper();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _customUrlController = TextEditingController();
  
  String _status = 'Bereit';
  bool _isImporting = false;
  bool _connectionTested = false;
  bool _connectionOk = false;
  ScraperResult? _lastResult;
  
  // Neue State für alternative Quellen
  String _selectedSource = 'winnersystem';
  final Map<String, String> _sourceUrls = {
    'winnersystem': 'https://winnersystem.org/archiv/',
    'lottozahlen': 'https://www.lottozahlenonline.de/',
    'lottoarchiv': 'https://www.lottoarchiv.de/',
  };
  
  @override
  void initState() {
    super.initState();
    _testConnection();
    
    // Beispiel-Daten vorbelegen
    _textController.text = '''03.12.2025 21 27 29 37 44 49
29.11.2025 11 31 6 22 25 44
26.11.2025 29 24 28 29 39 81''';
  }
  
  Future<void> _testConnection() async {
    setState(() {
      _status = 'Teste Verbindung zu winnersystem.org...';
      _isImporting = true;
    });
    
    final ok = await scraper.testConnection();
    
    setState(() {
      _connectionTested = true;
      _connectionOk = ok;
      _isImporting = false;
      _status = ok ? '✅ Verbindung erfolgreich' : '⚠️ Verbindung blockiert oder fehlgeschlagen';
    });
  }
  
  Future<void> _importYear() async {
    if (_yearController.text.isEmpty) return;
    
    final jahr = int.tryParse(_yearController.text);
    if (jahr == null || jahr < 1955 || jahr > DateTime.now().year) {
      setState(() {
        _status = '❌ Bitte gültiges Jahr eingeben (1955-${DateTime.now().year})';
      });
      return;
    }
    
    setState(() {
      _isImporting = true;
      _status = 'Importiere Jahr $jahr von ${_selectedSource}...';
    });
    
    ScraperResult result;
    
    // Versuche verschiedene Quellen
    if (_selectedSource == 'winnersystem') {
      result = await scraper.importYear('6aus49', jahr);
    } else if (_selectedSource == 'custom') {
      result = await _importFromCustomUrl();
    } else {
      result = await scraper.importFromAlternativeSource(_selectedSource, jahr);
    }
    
    setState(() {
      _isImporting = false;
      _lastResult = result;
      _status = result.toString();
    });
  }
  
  Future<ScraperResult> _importFromCustomUrl() async {
    if (_customUrlController.text.isEmpty) {
      return ScraperResult()
        ..success = false
        ..errorMessage = 'Bitte URL eingeben';
    }
    
    return await scraper.importFromCustomUrl(
      _customUrlController.text,
      int.tryParse(_yearController.text) ?? DateTime.now().year,
    );
  }
  
  Future<void> _importFromText() async {
    if (_textController.text.trim().isEmpty) return;
    
    setState(() {
      _isImporting = true;
      _status = 'Importiere aus Text...';
    });
    
    final result = await scraper.importFromText(_textController.text, '6aus49');
    
    setState(() {
      _isImporting = false;
      _lastResult = result;
      _status = result.toString();
    });
  }
  
  Future<void> _importExample() async {
    // Beispiel-Daten für Test
    final beispielText = '''03.12.2025 21 27 29 37 44 49
29.11.2025 11 31 6 22 25 44
26.11.2025 29 24 28 29 39 81
22.11.2025 15 18 21 29 32 33
19.11.2025 4 7 18 26 37 48''';
    
    _textController.text = beispielText;
    
    setState(() {
      _status = 'Beispiel-Daten geladen. Klicken Sie auf "Aus Text importieren"';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Datenimport'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verbindungsstatus - FIXED: Graue Schrift auf Schwarz
              Card(
                color: _connectionTested
                    ? (_connectionOk ? Colors.green[50] : Colors.orange[50])
                    : Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _connectionTested
                                ? (_connectionOk ? Icons.check_circle : Icons.warning)
                                : Icons.info,
                            color: _connectionTested
                                ? (_connectionOk ? Colors.green : Colors.orange)
                                : Colors.grey[700], // Dunkleres Grau für besseren Kontrast
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _status,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _connectionTested
                                    ? (_connectionOk ? Colors.green[800] : Colors.orange[800]) // Dunklere Farben
                                    : Colors.grey[900], // SCHWARZ statt grau
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!_connectionOk && _connectionTested)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Hinweis: Automatischer Import wird blockiert. Bitte verwenden Sie alternative Quellen.',
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.orange[800], // Dunkleres Orange
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // NEU: Alternative Datenquellen Auswahl
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌐 Alternative Datenquellen:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.blue[900], // Dunkleres Blau
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Datenquelle Auswahl
                      DropdownButtonFormField<String>(
                        value: _selectedSource,
                        decoration: const InputDecoration(
                          labelText: 'Datenquelle wählen',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'winnersystem',
                            child: Row(
                              children: [
                                const Icon(Icons.web, size: 16),
                                const SizedBox(width: 8),
                                const Text('winnersystem.org'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'lottozahlen',
                            child: Row(
                              children: [
                                const Icon(Icons.alternate_email, size: 16),
                                const SizedBox(width: 8),
                                const Text('lottozahlenonline.de'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Row(
                              children: [
                                const Icon(Icons.link, size: 16),
                                const SizedBox(width: 8),
                                const Text('Eigene URL eingeben'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSource = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Eigene URL Eingabe (nur wenn 'custom' ausgewählt)
                      if (_selectedSource == 'custom')
                        Column(
                          children: [
                            TextField(
                              controller: _customUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Eigene URL eingeben',
                                hintText: 'https://...',
                                border: OutlineInputBorder(),
                                labelStyle: TextStyle(color: Colors.black87),
                              ),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '💡 Tipp: Viele Lotto-Websites bieten historische Daten im CSV- oder Tabellenformat',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Manueller Text-Import (EMPFEHLUNG)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 ANLEITUNG für manuellen Import:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.green[900], // Dunkleres Grün
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '1. Gehen Sie zu einer Lotto-Website',
                        style: TextStyle(color: Colors.black87), // Dunkler
                      ),
                      Text(
                        '2. Suchen Sie historische Ziehungen',
                        style: TextStyle(color: Colors.black87),
                      ),
                      Text(
                        '3. Kopieren Sie Datum und 6 Lottozahlen',
                        style: TextStyle(color: Colors.black87),
                      ),
                      Text(
                        '4. Fügen Sie hier im Format ein:',
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: const Text(
                          'DD.MM.JJJJ ZZ ZZ ZZ ZZ ZZ ZZ\nDD.MM.JJJJ ZZ ZZ ZZ ZZ ZZ ZZ',
                          style: TextStyle(
                            fontFamily: 'monospace', 
                            fontSize: 12,
                            color: Colors.black, // Schwarz für Code
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: _importExample,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[900],
                              side: BorderSide(color: Colors.green[700]!),
                            ),
                            child: const Text('Beispiel laden'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Testen Sie zuerst mit Beispiel-Daten',
                              style: TextStyle(
                                fontSize: 12, 
                                color: Colors.grey[800], // Dunkleres Grau
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Text-Eingabe
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eingabe (eine Zeile pro Ziehung):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87, // Dunkler
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _textController,
                        maxLines: 10,
                        style: const TextStyle(color: Colors.black87), // Dunkler Text
                        decoration: const InputDecoration(
                          labelText: 'Lottozahlen einfügen',
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(),
                          hintText: 'Beispiel:\n03.12.2025 21 27 29 37 44 49\n29.11.2025 11 31 6 22 25 44',
                          hintStyle: TextStyle(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isImporting ? null : _importFromText,
                          icon: const Icon(Icons.paste),
                          label: const Text('Aus Text importieren'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              
              // Automatischer Import
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automatischer Import:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.orange[900], // Dunkleres Orange
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.black87),
                              decoration: const InputDecoration(
                                labelText: 'Jahr (z.B. 2023)',
                                labelStyle: TextStyle(color: Colors.black54),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isImporting ? null : _importYear,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Import starten'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Quelle: ${_selectedSource == 'custom' ? _customUrlController.text : _sourceUrls[_selectedSource] ?? _selectedSource}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Status-Anzeige - FIXED: Bessere Kontraste
              if (_isImporting || _lastResult != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isImporting ? Colors.blue[50] : 
                           (_lastResult?.success == true ? Colors.green[50] : Colors.orange[50]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isImporting ? Colors.blue[700]! : 
                            (_lastResult?.success == true ? Colors.green[700]! : Colors.orange[700]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isImporting)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _isImporting ? Colors.blue[900]! : 
                                   (_lastResult?.success == true ? Colors.green[900]! : Colors.orange[900]!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Tipps - FIXED: Dunklere Farben
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 ALTERNATIVE QUELLEN für Lotto-Daten:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.blue[900], // Dunkleres Blau
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSourceItem('1. https://www.lottozahlenonline.de/lotto/6aus49/archiv/'),
                      _buildSourceItem('2. https://www.lottozahlen-archiv.de/'),
                      _buildSourceItem('3. https://lottozahlen-nrw.de/lotto/6aus49/archiv/'),
                      _buildSourceItem('4. https://www.lottozahlen-aktuell.de/archiv/lotto-6aus49/'),
                      const SizedBox(height: 8),
                      Text(
                        '📋 Anleitung für alle Quellen:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Kopieren Sie Datum + 6 Lottozahlen',
                        style: TextStyle(color: Colors.black87),
                      ),
                      Text(
                        '• Format: "DD.MM.JJJJ ZZ ZZ ZZ ZZ ZZ ZZ"',
                        style: TextStyle(color: Colors.black87),
                      ),
                      Text(
                        '• Eine Zeile pro Ziehung',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSourceItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
