import 'package:shared_preferences/shared_preferences.dart';

Future<void> setPinnedApiImpl(
  String pinnedNotesKey,
  String id,
  bool pinned,
) async {
  final prefs = await SharedPreferences.getInstance();
  final pinnedIds = prefs.getStringList(pinnedNotesKey) ?? [];
  pinnedIds.remove(id);
  if (pinned) pinnedIds.add(id);
  await prefs.setStringList(pinnedNotesKey, pinnedIds);
}
