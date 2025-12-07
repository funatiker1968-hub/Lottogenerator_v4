import 'package:flutter/material.dart';
import 'services/lotto_api_importer.dart';

class LottoImportPage extends StatefulWidget {
  const LottoImportPage({super.key});

  @override
  State<LottoImportPage> createState() => _LottoImportPageState();
}

class _LottoImportPageState extends State<LottoImportPage> {
  final LottoApiImporter importer = LottoApiImporter();

  final TextEditingController _startJahr = TextEditingController(text: "2020");
  final TextEditingController _endJahr = TextEditingController(text: "2024");

  bool _isWorking = false;
  String _status = "Bereit. Bitte Jahresbereich eingeben.";
  ImporterResult? _lastResult;

  Future<void> _runImport(String spieltyp) async {
    final int? start = int.tryParse(_startJahr.text);
    final int? end = int.tryParse(_endJahr.text);

    if (start == null || end == null) {
      setState(() => _status = "❌ Bitte gültige Jahreszahlen eingeben.");
      return;
    }
    if (start > end) {
      setState(() => _status = "❌ Startjahr muss kleiner als Endjahr sein.");
      return;
    }

    setState(() {
      _isWorking = true;
      _status = "🔄 Importiere $spieltyp ($start–$end)…";
    });

    final result = await importer.importJahresBereich(
      spieltyp: spieltyp,
      startJahr: start,
      endJahr: end,
    );

    setState(() {
      _isWorking = false;
      _lastResult = result;
      _status = result.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lottozahlen Import"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // STATUS KASTEN ---------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isWorking
                    ? Colors.blue.shade50
                    : (_lastResult?.success == true
                        ? Colors.green.shade50
                        : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isWorking
                      ? Colors.blue
                      : (_lastResult?.success == true
                          ? Colors.green
                          : Colors.grey),
                ),
              ),
              child: Row(
                children: [
                  if (_isWorking)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (_isWorking) const SizedBox(width: 12),
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

            // BEREICHSEINGABE --------------------------------------------------
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "📅 Jahresbereich",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startJahr,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Von Jahr",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextField(
                            controller: _endJahr,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Bis Jahr",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // BUTTON 6aus49
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isWorking
                            ? null
                            : () => _runImport("6aus49"),
                        icon: const Icon(Icons.download),
                        label: const Text("Importiere Lotto 6aus49"),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // BUTTON EUROJACKPOT
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isWorking
                            ? null
                            : () => _runImport("eurojackpot"),
                        icon: const Icon(Icons.download),
                        label: const Text("Importiere Eurojackpot"),
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
