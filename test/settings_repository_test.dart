import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/settings/settings_repository_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/settings/settings_repository_mock.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final repository = SettingsRepositoryImpl();

  test('sin nada guardado devuelve los valores por defecto', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = (await repository.getSettings()).data!;
    expect(settings.autoSave, isTrue);
    expect(settings.requireEditMode, isTrue);
  });

  test('con solo un valor guardado, el otro queda por defecto', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepositoryImpl.autoSaveKey: false,
    });
    final settings = (await repository.getSettings()).data!;
    expect(settings.autoSave, isFalse);
    expect(settings.requireEditMode, isTrue);
  });

  test(
    'un valor de otro tipo da error y el estado queda por defecto',
    () async {
      SharedPreferences.setMockInitialValues({
        SettingsRepositoryImpl.autoSaveKey: 'sí',
      });
      expect((await repository.getSettings()).isError, isTrue);

      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(getSettingsUseCaseProvider).getSettings();
      expect(container.read(settingsStateProvider).autoSave, isTrue);
    },
  );

  test('guarda y lee los dos valores', () async {
    SharedPreferences.setMockInitialValues({});
    const settings = SettingsEntity(autoSave: false, requireEditMode: false);
    expect((await repository.saveSettings(settings)).isSuccess, isTrue);
    final saved = (await repository.getSettings()).data!;
    expect(saved.autoSave, isFalse);
    expect(saved.requireEditMode, isFalse);
  });

  test('el mock empieza por defecto y recuerda lo guardado', () async {
    final mock = SettingsRepositoryMock();
    expect((await mock.getSettings()).data!.autoSave, isTrue);
    await mock.saveSettings(const SettingsEntity(autoSave: false));
    expect((await mock.getSettings()).data!.autoSave, isFalse);
  });
}
