import 'package:flutter/material.dart';
import '../widgets/lotto_import_form.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto-Daten importieren'),
      ),
      body: const SingleChildScrollView(
        child: LottoImportForm(),
      ),
    );
  }
}
