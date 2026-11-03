import 'dart:convert';

import 'package:flutter/services.dart';

Future<Map<String, String>> getTranslationsApiImpl(String locale) async {
  final String jsonString = await rootBundle.loadString(
    'assets/translate_dictionaries/$locale.json',
  );
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  return jsonMap.map((key, value) => MapEntry(key, value.toString()));
}
