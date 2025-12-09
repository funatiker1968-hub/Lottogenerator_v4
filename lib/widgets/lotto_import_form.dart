import 'package:flutter/material.dart';

class LottoImportForm extends StatefulWidget {
  const LottoImportForm({Key? key}) : super(key: key);

  @override
  State<LottoImportForm> createState() => _LottoImportFormState();
}

class _LottoImportFormState extends State<LottoImportForm> {
  final _jahrController = TextEditingController();
  bool _isImporting = false;

  void _startImport() {
    // Korrektur: Kein Parameter, wenn die Methode keinen erwartet
    _importData();
  }

  Future<void> _importData() async {
    if (_jahrController.text.isEmpty) return;
    
    final jahr = int.tryParse(_jahrController.text);
    if (jahr == null) return;
    
    setState(() {
      _isImporting = true;
    });
    
    // Hier den Import durchführen
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isImporting = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Import für Jahr $jahr gestartet'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _jahrController,
            decoration: const InputDecoration(
              labelText: 'Jahr',
              hintText: 'z.B. 2024',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isImporting ? null : _startImport,
            child: _isImporting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 8),
                      Text('Importiere...'),
                    ],
                  )
                : const Text('Import starten'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _jahrController.dispose();
    super.dispose();
  }
}
