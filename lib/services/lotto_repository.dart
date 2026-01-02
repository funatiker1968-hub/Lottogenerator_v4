import '../models/lotto_draw.dart';

class LottoRepository {
  static final LottoRepository _instance = LottoRepository._internal();
  factory LottoRepository() => _instance;
  LottoRepository._internal();

  final List<LottoDraw> _lotto = [];
  final List<LottoDraw> _eurojackpot = [];

  List<LottoDraw> get lotto => List.unmodifiable(_lotto);
  List<LottoDraw> get eurojackpot => List.unmodifiable(_eurojackpot);

  bool get hasLotto => _lotto.isNotEmpty;
  bool get hasEurojackpot => _eurojackpot.isNotEmpty;

  void replaceLotto(List<LottoDraw> data) {
    _lotto
      ..clear()
      ..addAll(data);
  }

  void replaceEurojackpot(List<LottoDraw> data) {
    _eurojackpot
      ..clear()
      ..addAll(data);
  }

  void clearAll() {
    _lotto.clear();
    _eurojackpot.clear();
  }
}
