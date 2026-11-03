import 'package:shared_preferences/shared_preferences.dart';

List<String> _options = ["es"];

Future<String> getLanguageApiImpl(String keyShared) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? languageCode = prefs.getString(keyShared);
  if (languageCode == null) {
    return _options.first;
  }
  return _options.firstWhere((element) => element == languageCode);
}
