import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/web_scraper.dart';

class LottoImportPage extends StatefulWidget {
  const LottoImportPage({Key? key}) : super(key: key);

  @override
  _LottoImportPageState createState() => _LottoImportPageState();
}

class _LottoImportPageState extends State<LottoImportPage> {
  final LottoOnlineScraper scraper = LottoOnlineScraper();
  final TextEditingController _startJahrController = TextEditingController();
  final TextEditingController _endJahrController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  String _status = 'Bereit. Geben Sie einen Jahresbereich ein.';
  bool _isImporting = false;
  ScraperResult? _lastResult;
  
  @override
  void initState() {
    super.initState();
    _startJahrController.text = '2023';
    _endJahrController.text = '2024';
  }
  
  Future<void> _importJahresBereich() async {
    final startJahr = int.tryParse(_startJahrController.text);
    final endJahr = int.tryParse(_endJahrController.text);
    
    if (startJahr == null || endJahr == null) {
      setState(() { 
        _status = '❌ Bitte in beide Felder eine Jahreszahl eingeben.'; 
      });
      return;
    }
    
    if (startJahr > endJahr) {
      setState(() { 
        _status = '❌ "Von Jahr" muss kleiner sein als "Bis Jahr".'; 
      });
      return;
    }
    
    setState(() {
      _isImporting = true;
      _status = '🔄 Importiere Jahre $startJahr bis $endJahr...';
    });
    
    final result = await scraper.importVonLottozahlenOnline(
      startJahr: startJahr,
      endJahr: endJahr,
      spieltag: 'beide',
    );
    
    setState(() {
      _isImporting = false;
      _lastResult = result;
      _status = result.toString();
    });
  }

  Future<void> _importFromText() async {
    if (_textController.text.trim().isEmpty) {
      setState(() { _status = '❌ Bitte Text eingeben'; });
      return;
    }
    setState(() { _isImporting = true; _status = '🔄 Importiere aus Text...'; });
    final result = await scraper.importFromText(_textController.text, "6aus49");
    setState(() { _isImporting = false; _lastResult = result; _status = result.toString(); });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottozahlen Import'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Status-Anzeige
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isImporting ? Colors.blue[50] : 
                       (_lastResult?.success == true ? Colors.green[50] : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isImporting ? Colors.blue : 
                        (_lastResult?.success == true ? Colors.green : Colors.blue),
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
                    child: Text(_status, style: const TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Jahresbereich
            Card(
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📅 Jahresbereich (lottozahlenonline.de)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '⚠️ Diese Website verwendet JavaScript. Der automatische Import funktioniert nicht.',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 25),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startJahrController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Von Jahr',
                              labelStyle: TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(),
                              hintText: 'z.B. 2010',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Text('bis', style: TextStyle(color: Colors.black)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: _endJahrController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Bis Jahr',
                              labelStyle: TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(),
                              hintText: 'z.B. 2020',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 25),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isImporting ? null : _importJahresBereich,
                        icon: const Icon(Icons.download_for_offline),
                        label: const Text('Automatischen Import versuchen', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Manuelle Texteingabe (NUR EINMAL)
            Card(
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Manuelle Texteingabe',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'So gehts: 1. lottozahlenonline.de öffnen\n2. Jahr auswählen\n3. Tabelle kopieren\n4. Hier einfügen',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _textController,
                      maxLines: 8,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Beispiel:\n03.12.2025 21 27 29 37 44 49\n29.11.2025 11 31 6 22 25 44',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                        hintStyle: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isImporting ? null : _importFromText,
                        icon: const Icon(Icons.paste),
                        label: const Text('Aus Text importieren', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
