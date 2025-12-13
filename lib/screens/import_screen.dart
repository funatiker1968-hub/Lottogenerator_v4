import 'package:flutter/material.dart';

import '../services/lotto_import_service.dart';
import '../services/eurojackpot_import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final List<String> _log = [];
  bool _running = false;

  void _status(String msg) {
    setState(() {
      _log.add(msg);
    });
  }

  Future<void> _importLotto() async {
    setState(() {
      _log.clear();
      _running = true;
    });

    try {
      await LottoImportService().import6aus49FromAsset(
        status: _status,
      );
    } catch (e) {
      _status("❌ Fehler Lotto-Import: $e");
    }

    setState(() => _running = false);
  }

  Future<void> _importEurojackpot() async {
    setState(() {
      _log.clear();
      _running = true;
    });

    try {
      await EurojackpotImportService.instance.importIfEmpty(
        status: _status,
      );
    } catch (e) {
      _status("❌ Fehler Eurojackpot-Import: $e");
    }

    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datenimport'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.confirmation_number),
                    label: const Text('Lotto 6aus49 importieren'),
                    onPressed: _running ? null : _importLotto,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.euro),
                    label: const Text('Eurojackpot importieren'),
                    onPressed: _running ? null : _importEurojackpot,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  return Text(
                    _log[index],
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
