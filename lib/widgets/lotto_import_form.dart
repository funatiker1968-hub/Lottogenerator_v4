import 'package:flutter/material.dart';
import '../services/lottozahlenonline_scraper.dart';

class LottoImportForm extends StatefulWidget {
  const LottoImportForm({super.key});

  @override
  State<LottoImportForm> createState() => _LottoImportFormState();
}

class _LottoImportFormState extends State<LottoImportForm> {
  int? _startYear;
  int? _endYear;

  final int _minYear = 1955;
  final int _maxYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _startYear = _minYear;
    _endYear = _maxYear;
  }

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(_maxYear - _minYear + 1, (i) => _minYear + i);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Startjahr'),
            value: _startYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (y) => setState(() => _startYear = y),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Endjahr'),
            value: _endYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (y) => setState(() => _endYear = y),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_startYear != null && _endYear != null && _startYear! <= _endYear!)
              ? () async {
                  final res = await LottozahlenOnlineScraper.importVonLottozahlenOnline(
                    startJahr: _startYear!, endJahr: _endYear!
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.toString())),
                  );
                }
              : null,
            child: const Text('Import starten'),
          ),
        ],
      ),
    );
  }
}
