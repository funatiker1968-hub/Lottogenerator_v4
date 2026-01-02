import 'lotto_draw.dart';

class ImportResult {
  final List<LottoDraw> draws;
  final int valid;
  final int errors;

  ImportResult({
    required this.draws,
    required this.valid,
    required this.errors,
  });
}
