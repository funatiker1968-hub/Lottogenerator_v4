import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> entries;

  const StatisticsScreen({
    super.key,
    required this.title,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final e = entries[index];
          return ListTile(
            title: Text(e['date'].toString()),
            subtitle: Text(
              'Zahlen: ${e['numbers']}'
              '${e['extra'] != null ? ' | Extra: ${e['extra']}' : ''}',
            ),
          );
        },
      ),
    );
  }
}
