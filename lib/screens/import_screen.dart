import 'package:flutter/material.dart';
import '../services/lotto_import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final List<String> _log = [];
  bool _running = false;

  void _addLog(String msg) {
    setState(() {
      _log.add(msg);
    });
  }

  Future<void> _import6aus49() async {
    if (_running) return;
    setState(() {
      _running = true;
      _log.clear();
    });

    final importer = LottoImportService();

    try {
      await importer.import6aus49FromAsset(
        status: _addLog,
      );
      _addLog("=== IMPORT ABGESCHLOSSEN ===");
    } catch (e) {
      _addLog("❌ FEHLER: $e");
    }

    setState(() {
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daten importieren')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: _running ? null : _import6aus49,
              child: const Text('6aus49 JSON importieren'),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _log.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    _log[index],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
