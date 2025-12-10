import 'package:flutter/material.dart';
import '../services/lotto_import_service.dart';

class LottoImportPage extends StatefulWidget {
  const LottoImportPage({super.key});

  @override
  State<LottoImportPage> createState() => _LottoImportPageState();
}

class _LottoImportPageState extends State<LottoImportPage> {
  final _importService = LottoImportService();
  final _start = TextEditingController(text: "1955");
  final _ende = TextEditingController(text: "${DateTime.now().year}");
  String _spieltyp = "6aus49";

  bool _busy = false;
  final List<String> _log = [];

  void _append(String msg) {
    setState(() => _log.add(msg));
  }

  Future<void> _startImport() async {
    final s = int.tryParse(_start.text) ?? 1955;
    final e = int.tryParse(_ende.text) ?? DateTime.now().year;

    setState(() {
      _busy = true;
      _log.clear();
    });

    await _importService.importBereich(
      start: s,
      ende: e,
      spieltyp: _spieltyp,
      status: _append,
    );

    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lotto-Import")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _start,
                  decoration: const InputDecoration(labelText: "Startjahr"),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _ende,
                  decoration: const InputDecoration(labelText: "Endjahr"),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 16),

            DropdownButton<String>(
              value: _spieltyp,
              items: const [
                DropdownMenuItem(value: "6aus49", child: Text("Lotto 6aus49")),
                DropdownMenuItem(value: "Eurojackpot", child: Text("Eurojackpot")),
              ],
              onChanged: (v) => setState(() => _spieltyp = v!),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _busy ? null : _startImport,
              child: _busy
                  ? const Text("Import läuft …")
                  : const Text("Import starten"),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  children: _log
                      .map((e) => Text(e, style: const TextStyle(fontSize: 13)))
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
