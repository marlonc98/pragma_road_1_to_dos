import 'package:shared_preferences/shared_preferences.dart';

Future<int> countPinnedNotesApiImpl(String pinnedNotesKey) async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList(pinnedNotesKey) ?? []).length;
}
