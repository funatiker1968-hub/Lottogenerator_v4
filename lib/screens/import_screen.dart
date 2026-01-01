import 'package:flutter/material.dart';
import '../services/txt_lotto_parser.dart';
import '../models/lotto_draw.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  List<LottoDraw>? lottoDraws;
  String? error;

  Future<void> loadLotto() async {
    try {
      final draws = TxtLottoParser.parseLotto1955_2025(
        'assets/data/lotto_1955_2025.txt',
      );
      setState(() {
        lottoDraws = draws;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        lottoDraws = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import-Test (TXT)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: loadLotto,
              child: const Text('Lotto 6aus49 TXT laden'),
            ),
            const SizedBox(height: 16),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),

            if (lottoDraws != null) ...[
              Text('Ziehungen: ${lottoDraws!.length}'),
              const SizedBox(height: 8),
              Text('Erste Ziehung: ${lottoDraws!.first.date}'),
              Text('Letzte Ziehung: ${lottoDraws!.last.date}'),
              const SizedBox(height: 12),
              Text(
                'Beispiel:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(lottoDraws!.first.toString()),
            ],
          ],
        ),
      ),
    );
  }
}
