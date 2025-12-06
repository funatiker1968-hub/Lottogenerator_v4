import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/lottozahlenonline_scraper.dart';

class LottoImportPage extends StatefulWidget {
  const LottoImportPage({Key? key}) : super(key: key);

  @override
  _LottoImportPageState createState() => _LottoImportPageState();
}

class _LottoImportPageState extends State<LottoImportPage> {
  final LottozahlenOnlineScraper scraper = LottozahlenOnlineScraper();
  final TextEditingController _startJahrController = TextEditingController();
  final TextEditingController _endJahrController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  String _status = 'Bereit. Geben Sie einen Jahresbereich ein.';
  bool _isImporting = false;
  ScraperResult? _lastResult;
  
  @override
  void initState() {
    super.initState();
    // Vorbelegen mit Beispiel-Jahren zum Testen
    _startJahrController.text = '2023';
    _endJahrController.text = '2024';
  }
  

  Future<void> _importFromText() async {
    if (_textController.text.trim().isEmpty) {
      setState(() { _status = "❌ Bitte Text eingeben"; });
      return;
    }
    setState(() { _isImporting = true; _status = "🔄 Importiere aus Text..."; });
    final result = await scraper.importFromText(_textController.text, "6aus49");
    setState(() { _isImporting = false; _lastResult = result; _status = result.toString(); });
  }
  Future<void> _importJahresBereich() async {
    // 1. Eingaben lesen und prüfen
    final startJahr = int.tryParse(_startJahrController.text);
    final endJahr = int.tryParse(_endJahrController.text);
    
    if (startJahr == null || endJahr == null) {
      setState(() { 
        _status = '❌ Bitte in beide Felder eine Jahreszahl eingeben (z.B. 2020).'; 
      });
      return;
    }
    
    if (startJahr > endJahr) {
      setState(() { 
        _status = '❌ "Von Jahr" ($startJahr) muss kleiner oder gleich "Bis Jahr" ($endJahr) sein.'; 
      });
      return;
    }
    
    // 2. Status "Import läuft" anzeigen
    setState(() {
      _isImporting = true;
      _status = '🔄 Importiere Jahre $startJahr bis $endJahr von lottozahlenonline.de...\n(Dies kann einige Zeit dauern)';
    });
    
    // 3. Den Scraper ausführen
    final result = await scraper.importJahresBereich(
      startJahr: startJahr,
      endJahr: endJahr,
      spieltag: 'beide',
    );
    
    // 4. Ergebnis anzeigen
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
        title: const Text('Lottozahlen Import'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Text(
                      _status,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Eingabe-Karte
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📅 Jahresbereich auswählen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Importiert alle Lottoziehungen (Mittwoch & Samstag) für den angegebenen Zeitraum von lottozahlenonline.de.',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 25),
                    
                    // Jahres-Eingabefelder
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startJahrController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Von Jahr',
                              border: OutlineInputBorder(),
                              hintText: 'z.B. 2010',
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
                            decoration: const InputDecoration(
                              labelText: 'Bis Jahr',
                              border: OutlineInputBorder(),
                              hintText: 'z.B. 2020',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Hinweis: Beginne mit einem kleinen Bereich (z.B. 2023-2023) zum Testen.',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Import-Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isImporting ? null : _importJahresBereich,
                        icon: _isImporting 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.download_for_offline),
                        label: Text(
                          _isImporting ? 'Import läuft...' : 'Jahresbereich importieren',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          // Manuelle Texteingabe
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📝 Manuelle Texteingabe:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Fügen Sie hier kopierte Lottozahlen ein (eine Zeile pro Ziehung):",
                    style: TextStyle(color: Colors.black87),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: "Beispiel:\\n03.12.2025 21 27 29 37 44 49\\n29.11.2025 11 31 6 22 25 44",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importFromText,
                      icon: Icon(Icons.paste),
                      label: Text("Aus Text importieren"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Manuelle Texteingabe
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📝 Manuelle Texteingabe:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Fügen Sie hier kopierte Lottozahlen ein (eine Zeile pro Ziehung):",
                    style: TextStyle(color: Colors.black87),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: "Beispiel:\\n03.12.2025 21 27 29 37 44 49\\n29.11.2025 11 31 6 22 25 44",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importFromText,
                      icon: Icon(Icons.paste),
                      label: Text("Aus Text importieren"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 10),
                      Text("Manueller Import notwendig", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text("1. Gehen Sie zu lottozahlenonline.de", style: TextStyle(color: Colors.black)),
                  Text("2. Wählen Sie ein Jahr aus", style: TextStyle(color: Colors.black)),
                  Text("3. Kopieren Sie die gesamte Tabelle", style: TextStyle(color: Colors.black)),
                  Text("4. Fügen Sie sie unten ein", style: TextStyle(color: Colors.black)),
                  SizedBox(height: 10),
                  Text("Format: DD.MM.JJJJ ZZ ZZ ZZ ZZ ZZ ZZ", style: TextStyle(fontFamily: "monospace", color: Colors.black)),
                ],
              ),
            ),
          ),
            
            // Tipps-Karte
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Tipps für erfolgreichen Import:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Teste zuerst mit einem einzelnen Jahr (z.B. 2023-2023)'),
                    Text('• Ein Jahr hat etwa 104 Ziehungen (52× Mittwoch + 52× Samstag)'),
                    Text('• Der Import großer Bereiche (z.B. 2000-2025) kann mehrere Minuten dauern'),
                    Text('• Stelle sicher, dass du mit dem Internet verbunden bist'),
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
