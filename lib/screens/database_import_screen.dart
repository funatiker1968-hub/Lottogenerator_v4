// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/txt_lotto_parser.dart';
import '../services/txt_eurojackpot_parser.dart';
import '../models/parse_result.dart';

enum ImportType { lotto, eurojackpot }

class DatabaseImportScreen extends StatefulWidget {
  const DatabaseImportScreen({super.key});

  @override
  State<DatabaseImportScreen> createState() => _DatabaseImportScreenState();
}

class _DatabaseImportScreenState extends State<DatabaseImportScreen> {
  ImportType _type = ImportType.lotto;
  final TextEditingController _controller = TextEditingController();

  ParseResult? _result;
  String _status = '';

  Future<void> _loadAsset() async {
    try {
      final path = _type == ImportType.lotto
          ? 'assets/data/lotto_1955_2025.txt'
          : 'assets/data/eurojackpot_2012_2025.txt';

      final text = await rootBundle.loadString(path);
      _controller.text = text;
      _result = null;
      _status = 'Asset geladen: $path';
      setState(() {});
    } catch (_) {
      _status = 'FEHLER: Asset nicht gefunden';
      _result = null;
      setState(() {});
    }
  }

  void _parse() {
    try {
      _result = _type == ImportType.lotto
          ? parseLottoTxt(_controller.text)
          : parseEurojackpotTxt(_controller.text);

      _status =
          'OK: ${_result!.valid} gültig, ${_result!.errors} Fehler';
    } catch (_) {
      _status = 'PARSER-FEHLER';
      _result = null;
    }
    setState(() {});
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
          // Header (zweistufig dunkler)
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
                  tooltip: 'Asset laden',
                  onPressed: _loadAsset,
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Parser ausführen',
                  onPressed: _parse,
                ),
              ],
            ),
          ),

          // Textfeld
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
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

          // Status + Vorschau
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
                if (_result != null && _result!.entries.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Vorschau (erste 5 Einträge):',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  for (final row in _result!.entries.take(5))
                    Text(
                      row.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
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
