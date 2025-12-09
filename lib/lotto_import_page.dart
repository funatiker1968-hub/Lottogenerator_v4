import 'package:flutter/material.dart';
import '../services/multi_lotto_importer.dart';

// Entferne oder ersetze ImporterResult
// class ImporterResult {
//   final bool success;
//   final String message;
//   ImporterResult(this.success, this.message);
// }

class LottoImportPage extends StatefulWidget {
  const LottoImportPage({super.key});

  @override
  State<LottoImportPage> createState() => _LottoImportPageState();
}

class _LottoImportPageState extends State<LottoImportPage> {
  final MultiLottoImporter _importer = MultiLottoImporter();
  bool _isImporting = false;
  String _status = '';
  
  final TextEditingController _startYearController = TextEditingController();
  final TextEditingController _endYearController = TextEditingController();

  Future<void> _importRange() async {
    final start = int.tryParse(_startYearController.text) ?? DateTime.now().year;
    final end = int.tryParse(_endYearController.text) ?? DateTime.now().year;
    
    setState(() {
      _isImporting = true;
      _status = 'Importiere Daten von $start bis $end...';
    });

    try {
      // Verwende die korrekte Methode aus MultiLottoImporter
      await _importer.importiereJahresBereich(start, end); // Ändere den Methodennamen hier
      
      setState(() {
        _status = 'Import erfolgreich! $start-$end importiert.';
      });
    } catch (e) {
      setState(() {
        _status = 'Fehler beim Import: $e';
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto Import'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _startYearController,
              decoration: const InputDecoration(
                labelText: 'Startjahr',
                hintText: 'z.B. 2020',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endYearController,
              decoration: const InputDecoration(
                labelText: 'Endjahr',
                hintText: 'z.B. 2024',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isImporting ? null : _importRange,
              child: _isImporting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 8),
                        Text('Importiere...'),
                      ],
                    )
                  : const Text('Import starten'),
            ),
            const SizedBox(height: 32),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_status),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }
}
