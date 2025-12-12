import 'package:flutter/material.dart';
import '../services/lotto_import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _importService = LottoImportService();

  final _lottoStart = TextEditingController(text: "1955");
  final _lottoEnd = TextEditingController(text: "${DateTime.now().year}");

  final _euroStart = TextEditingController(text: "2012");
  final _euroEnd = TextEditingController(text: "${DateTime.now().year}");

  bool _busy = false;

  double _progressLotto = 0;
  double _progressEuro = 0;
  double _progressTotal = 0;

  String _phase = "Bereit";
  final List<String> _log = [];

  void _logLine(String text) {
    setState(() {
      _log.add(text);
      if (_log.length > 300) _log.removeAt(0);
    });
  }

  void _updateProgress(String msg) {
    setState(() => _phase = msg);
  }

  Future<void> _start() async {
    if (_busy) return;

    final ls = int.tryParse(_lottoStart.text) ?? 1955;
    final le = int.tryParse(_lottoEnd.text) ?? DateTime.now().year;

    final es = int.tryParse(_euroStart.text) ?? 2012;
    final ee = int.tryParse(_euroEnd.text) ?? DateTime.now().year;

    setState(() {
      _busy = true;
      _log.clear();
      _phase = "Starte Import…";
      _progressLotto = 0;
      _progressEuro = 0;
      _progressTotal = 0;
    });

    try {
      await _importService.importBereich(
        start: ls,
        ende: le,
        spieltyp: "6aus49",
        status: _logLine,
      );

      await _importService.importBereich(
        start: es,
        ende: ee,
        spieltyp: "Eurojackpot",
        status: _logLine,
      );

      setState(() {
        _phase = "Fertig!";
      });
    } catch (e) {
      _logLine("❌ Fehler: $e");
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daten-Import")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _lottoStart,
                  decoration: const InputDecoration(labelText: "Lotto Startjahr"),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lottoEnd,
                  decoration: const InputDecoration(labelText: "Lotto Endjahr"),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _euroStart,
                  decoration: const InputDecoration(labelText: "Euro Startjahr"),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _euroEnd,
                  decoration: const InputDecoration(labelText: "Euro Endjahr"),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),

            const SizedBox(height: 12),
            Text("Phase: $_phase"),

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _start,
              child: Text(_busy ? "Import läuft…" : "Import starten"),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  children: _log
                      .map((e) =>
                          Text(e, style: const TextStyle(fontSize: 13, color: Colors.white)))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
