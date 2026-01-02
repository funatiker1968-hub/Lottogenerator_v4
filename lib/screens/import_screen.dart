// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/parse_result.dart';
import '../models/lotto_draw.dart';
import '../services/txt_lotto_parser.dart';
import '../services/txt_eurojackpot_parser.dart';
import '../services/lotto_repository.dart';

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
    try {
      final path = _type == ImportType.lotto
          ? 'assets/data/lotto_1955_2025.txt'
          : 'assets/data/eurojackpot_2012_2025.txt';

      _controller.text = await rootBundle.loadString(path);
      _result = null;
      _status = 'Asset geladen: $path';
      setState(() {});
    } catch (_) {
      _status = 'FEHLER: Asset nicht gefunden';
      _result = null;
      setState(() {});
    }
  }

  void _parseAndStore() {
    try {
      final repo = LottoRepository();

      if (_type == ImportType.lotto) {
        final res = parseLottoTxt(_controller.text);
        repo.replaceLotto(res.entries.cast<LottoDraw>());
        _result = res;
        _status = 'LOTTO IMPORT OK: ${res.valid} Ziehungen';
      } else {
        final res = parseEurojackpotTxt(_controller.text);
        repo.replaceEurojackpot(res.entries.cast<LottoDraw>());
        _result = res;
        _status = 'EUROJACKPOT IMPORT OK: ${res.valid} Ziehungen';
      }
    } catch (_) {
      _status = 'IMPORT FEHLGESCHLAGEN';
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
          // Header
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
                  onSelected: (_) => setState(() => _type = ImportType.lotto),
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
                  icon: const Icon(Icons.save),
                  onPressed: _parseAndStore,
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

          // STATUS + SICHTBARE VORSCHAU
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
                    'Vorschau (erste 3 Ziehungen):',
                    style: TextStyle(color: Colors.white),
                  ),
                  for (final e in _result!.entries.take(3))
                    Text(
                      e.toString(),
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
