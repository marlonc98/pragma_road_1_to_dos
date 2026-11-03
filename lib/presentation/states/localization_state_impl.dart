import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/states/localization_state.dart';

class LocalizationStateImpl extends Notifier<Map<String, String>>
    implements LocalizationState {
  @override
  Map<String, String> build() {
    _loading = _load();
    return {};
  }

  Future<void>? _loading;

  String _locale = 'es';
  @override
  String get locale => _locale;
  @override
  set locale(String locale) {
    _locale = locale;
    _loading = _load();
  }

  @override
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    state = await ref
        .read(localizationRepositoryProvider)
        .getTranslations(_locale);
  }

  @override
  String translate(String keyText, {Map<String, dynamic>? values}) {
    String? string = state[keyText];
    if (string == null) return keyText;
    if (values == null || values.keys.isEmpty) {
      return string;
    }
    for (String key in values.keys) {
      try {
        string = string!.replaceAll('{$key}', '${values[key]}');
      } catch (e) {
        return "";
      }
    }
    return string!;
  }
}
