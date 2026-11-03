abstract class LocalizationState {
  abstract String locale;
  Future<void> load();
  String translate(String keyText, {Map<String, dynamic>? values});
}
