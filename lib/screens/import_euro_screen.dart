import 'package:flutter/material.dart';
import '../services/eurojackpot_importer.dart';

class ImportEuroScreen extends StatefulWidget {
  const ImportEuroScreen({super.key});

  @override
  State<ImportEuroScreen> createState() => _ImportEuroScreenState();
}

class _ImportEuroScreenState extends State<ImportEuroScreen> {
  final List<String> _log = [];
  bool _laeuft = false;

  void _addLog(String msg) {
    setState(() => _log.add(msg));
  }

  Future<void> _startImport() async {
    setState(() {
      _log.clear();
      _laeuft = true;
    });

    await EurojackpotImporter.importiereAlles(_addLog);

    setState(() => _laeuft = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Eurojackpot Import")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _laeuft ? null : _startImport,
            child: const Text("Eurojackpot importieren (2012–heute)"),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView(
                children: _log
                    .map((e) => Text(e,
                        style: const TextStyle(color: Colors.green)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
