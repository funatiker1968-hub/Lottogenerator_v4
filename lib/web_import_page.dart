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
  
  String _status = 'Bereit';
  bool _isImporting = false;
  bool _connectionTested = false;
  bool _connectionOk = false;
  ScraperResult? _lastResult;
  
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
      _status = 'Importiere Jahr $jahr... (kann blockiert werden)';
    });
    
    final result = await scraper.importYear('6aus49', jahr);
    
    setState(() {
      _isImporting = false;
      _lastResult = result;
      _status = result.toString();
    });
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
              // Verbindungsstatus
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
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _status,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _connectionTested
                                    ? (_connectionOk ? Colors.green : Colors.orange)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!_connectionOk && _connectionTested)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Hinweis: Automatischer Import wird blockiert. Bitte kopieren Sie manuell.',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
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
                      const Text(
                        '📋 ANLEITUNG für winnersystem.org:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 10),
                      const Text('1. Gehen Sie zu winnersystem.org/archiv/'),
                      const Text('2. Wählen Sie "Lotto 6aus49" und ein Jahr'),
                      const Text('3. Klicken Sie auf die gewünschte Ziehung'),
                      const Text('4. Kopieren Sie NUR die 6 Lottozahlen'),
                      const Text('5. Fügen Sie hier im Format ein:'),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: const Text(
                          'DD.MM.JJJJ ZZ ZZ ZZ ZZ ZZ ZZ\nDD.MM.JJJJ ZZ ZZ ZZ ZZ ZZ ZZ',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: _importExample,
                            child: const Text('Beispiel laden'),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Testen Sie zuerst mit Beispiel-Daten',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      const Text(
                        'Eingabe (eine Zeile pro Ziehung):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _textController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          labelText: 'Lottozahlen einfügen',
                          border: OutlineInputBorder(),
                          hintText: 'Beispiel:\n03.12.2025 21 27 29 37 44 49\n29.11.2025 11 31 6 22 25 44',
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
                      const Text(
                        'Automatischer Versuch (wahrscheinlich blockiert):',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Jahr (z.B. 2023)',
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
                            child: const Text('Versuchen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Status-Anzeige
              if (_isImporting || _lastResult != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isImporting ? Colors.blue[50] : 
                           (_lastResult?.success == true ? Colors.green[50] : Colors.orange[50]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isImporting ? Colors.blue : 
                            (_lastResult?.success == true ? Colors.green : Colors.orange),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isImporting)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _isImporting ? Colors.blue : 
                                   (_lastResult?.success == true ? Colors.green : Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Tipps
              Card(
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 TIPPS für erfolgreichen Import:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      SizedBox(height: 8),
                      Text('• Kopieren Sie NUR die 6 Lottozahlen (ohne Superzahl/Gewinnklassen)'),
                      Text('• Format: "DD.MM.JJJJ ZZ ZZ ZZ ZZ ZZ ZZ"'),
                      Text('• Eine Zeile pro Ziehung'),
                      Text('• Zahlen müssen zwischen 1 und 49 liegen'),
                      SizedBox(height: 8),
                      Text(
                        'Beispiel für eine Zeile:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '03.12.2025 21 27 29 37 44 49',
                        style: TextStyle(fontFamily: 'monospace', backgroundColor: Colors.white),
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
}
