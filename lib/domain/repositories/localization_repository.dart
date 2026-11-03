abstract class LocalizationRepository {
  Future<String> getLanguage();
  Future<Map<String, String>> getTranslations(String locale);
}
