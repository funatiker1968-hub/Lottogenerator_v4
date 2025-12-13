import 'package:flutter/material.dart';
import 'services/lotto_import_service.dart';

class LottoImportPage extends StatefulWidget {
  const LottoImportPage({super.key});

  @override
  State<LottoImportPage> createState() => _LottoImportPageState();
}

class _LottoImportPageState extends State<LottoImportPage> {
  final _log = <String>[];
  bool _running = false;

  void _add(String s) {
    setState(() => _log.add(s));
  }

  Future<void> _startImport() async {
    setState(() {
      _log.clear();
      _running = true;
    });

    final service = LottoImportService();

    await service.import6aus49FromAsset(
      status: _add,
    );

    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datenimport')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _running ? null : _startImport,
            child: const Text('6aus49 JSON importieren'),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: _log.map((e) => Text(e)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
