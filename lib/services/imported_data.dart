class ImportedData {
  static List<Map<String, dynamic>> lotto = [];
  static List<Map<String, dynamic>> euro = [];

  static void setLotto(List<Map<String, dynamic>> data) {
    lotto = data;
  }

  static void setEuro(List<Map<String, dynamic>> data) {
    euro = data;
  }

  static bool get hasLotto => lotto.isNotEmpty;
  static bool get hasEuro => euro.isNotEmpty;
}
