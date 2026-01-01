import 'package:flutter/material.dart';

class DatabaseImportScreen extends StatelessWidget {
  const DatabaseImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgDark = Colors.grey.shade800;
    final bgDarker = Colors.grey.shade900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datenimport'),
        backgroundColor: bgDarker,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              bgDarker,
            ],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // STATUS-KACHELN
            Row(
              children: [
                _statusTile(
                  title: 'Lotto 6aus49',
                  lines: const [
                    'Ziehungen: 0',
                    'Von: -',
                    'Bis: -',
                  ],
                ),
                const SizedBox(width: 8),
                _statusTile(
                  title: 'Eurojackpot',
                  lines: const [
                    'Ziehungen: 0',
                    'Von: -',
                    'Bis: -',
                  ],
                ),
                const SizedBox(width: 8),
                _statusTile(
                  title: 'Gesamt',
                  lines: const [
                    'Ziehungen: 0',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // HAUPTBEREICH
            Expanded(
              child: Row(
                children: [
                  // LINKS: DATENLISTE
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const SingleChildScrollView(
                        child: Text(
                          'Ziehungen erscheinen hier...\n\n'
                          'Beispiel:\n'
                          'Mi 10.01.2024  1 2 3 4 5 6 | SZ 7\n'
                          'Sa 13.01.2024  3 8 12 19 33 45 | SZ 2\n',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // RECHTS: LOG
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const SingleChildScrollView(
                        child: Text(
                          '[LOG]\n'
                          'Bereit.\n'
                          'Warte auf Import...\n',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('LOTTO IMPORT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // TODO: TXT-Import Lotto
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('EUROJACKPOT IMPORT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // TODO: TXT-Import Eurojackpot
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statusTile({
    required String title,
    required List<String> lines,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade500),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            for (final l in lines)
              Text(
                l,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
