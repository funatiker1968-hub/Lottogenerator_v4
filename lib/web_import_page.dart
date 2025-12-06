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
                            'Hinweis: Die Website blockiert wahrscheinlich automatische Zugriffe. Bitte verwenden Sie die manuelle Text-Eingabe.',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Manueller Text-Import (EMPFEHLUNG)
              const Text(
                'Manueller Import (empfohlen)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'So gehen Sie vor:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Gehen Sie zu winnersystem.org/archiv/'),
                      const Text('2. Wählen Sie ein Jahr aus (z.B. 2023)'),
                      const Text('3. Markieren und kopieren Sie die Lottozahlen'),
                      const Text('4. Fügen Sie sie hier ein'),
                      const Text('5. Klicken Sie auf "Aus Text importieren"'),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _textController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Lottozahlen hier einfügen',
                          border: OutlineInputBorder(),
                          hintText: 'Beispiel:\n04.12.2023 3 7 12 25 34 42 SZ:8\n02.12.2023 5 11 19 23 37 45 SZ:2',
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
              
              // Automatischer Import (wahrscheinlich blockiert)
              const Text(
                'Automatischer Import (experimentell)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Einzelnes Jahr automatisch importieren:'),
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
                      const SizedBox(height: 10),
                      const Text(
                        '⚠️ Achtung: Dieser Weg wird sehr wahrscheinlich von der Website blockiert!',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
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
            ],
          ),
        ),
      ),
    );
  }
}
