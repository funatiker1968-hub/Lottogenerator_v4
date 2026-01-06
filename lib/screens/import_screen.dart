// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/txt_lotto_parser.dart';
import '../services/txt_eurojackpot_parser.dart';
import '../models/parse_result.dart';
import 'statistics_screen.dart';

enum ImportType { lotto, eurojackpot }

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  ImportType _type = ImportType.lotto;
  final TextEditingController _controller = TextEditingController();

  ParseResult? _result;
  String _status = '';

  Future<void> _loadAsset() async {
    final path = _type == ImportType.lotto
        ? 'assets/data/lotto_1955_2025.txt'
        : 'assets/data/eurojackpot_2012_2025.txt';

    try {
      _controller.text = await rootBundle.loadString(path);
      _result = null;
      _status = 'Asset geladen: $path';
    } catch (_) {
      _result = null;
      _status = 'FEHLER: Asset nicht gefunden';
    }
    setState(() {});
  }

  void _parse() {
    try {
      _result = _type == ImportType.lotto
          ? parseLottoTxt(_controller.text)
          : parseEurojackpotTxt(_controller.text);

      _status =
          'OK: ${_result!.valid} gültig, ${_result!.errors} Fehler';
    } catch (_) {
      _result = null;
      _status = 'PARSER-FEHLER';
    }
    setState(() {});
  }

  void _openStatistics() {
    if (_result == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatisticsScreen(
          title: _type == ImportType.lotto
              ? 'Lotto Statistik'
              : 'Eurojackpot Statistik',
          entries: _result!.entries,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade700,
                  Colors.grey.shade900,
                ],
              ),
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Lotto 6aus49'),
                  selected: _type == ImportType.lotto,
                  onSelected: (_) =>
                      setState(() => _type = ImportType.lotto),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Eurojackpot'),
                  selected: _type == ImportType.eurojackpot,
                  onSelected: (_) =>
                      setState(() => _type = ImportType.eurojackpot),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _loadAsset,
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _parse,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'TXT einfügen oder Asset laden …',
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _openStatistics,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Statistik öffnen'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
