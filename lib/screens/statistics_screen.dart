import 'package:flutter/material.dart';
import '../services/statistics/statistics_db_adapter.dart';

class StatisticsScreen extends StatefulWidget {
  final String spieltyp;
  const StatisticsScreen({super.key, required this.spieltyp});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsDbAdapter _db = StatisticsDbAdapter();

  bool _loading = true;
  int _count = 0;
  DateTime? _first;
  DateTime? _last;
  Map<int, int> _freq = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _count = await _db.count(widget.spieltyp);
      final r = await _db.range(widget.spieltyp);
      _first = r['first'];
      _last = r['last'];
      _freq = await _db.frequency(widget.spieltyp, widget.spieltyp == '6aus49' ? 6 : 5);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? '-' : '${d.day}.${d.month}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final top = _freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text('Statistik – ${widget.spieltyp}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Ziehungen: $_count'),
                    Text('Von: ${_fmt(_first)}'),
                    Text('Bis: ${_fmt(_last)}'),
                    const Divider(),
                    const Text('Top 10 Zahlen', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...top.take(10).map((e) => Text('Zahl ${e.key}: ${e.value}×')),
                  ],
                ),
    );
  }
}
