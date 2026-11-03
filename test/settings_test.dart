import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/settings/settings_repository_impl.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/settings_repository.dart';
import 'package:gestor_tareas_personales/presentation/pages/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingSettingsRepository extends SettingsRepository {
  @override
  Future<AsyncState<SettingsEntity>> getSettings() async =>
      AsyncState.fromError(Exception());

  @override
  Future<AsyncState<void>> saveSettings(SettingsEntity settings) async =>
      AsyncState.fromError(Exception());
}

void main() {
  ProviderContainer createContainer([SettingsRepository? repository]) {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          repository ?? SettingsRepositoryImpl(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('por defecto hay autoguardado y hay que tocar Editar', () {
    final settings = createContainer().read(settingsStateProvider);
    expect(settings.autoSave, isTrue);
    expect(settings.requireEditMode, isTrue);
  });

  test('sin nada guardado, cargar deja los valores por defecto', () async {
    final container = createContainer();
    await container.read(getSettingsUseCaseProvider).getSettings();
    expect(container.read(settingsStateProvider).autoSave, isTrue);
    expect(container.read(settingsStateProvider).requireEditMode, isTrue);
  });

  test('LoadUseCase carga lo guardado en una sesión anterior', () async {
    await SettingsRepositoryImpl().saveSettings(
      const SettingsEntity(autoSave: false, requireEditMode: false),
    );
    final container = createContainer();
    await container.read(loadUseCaseProvider).call();
    expect(container.read(settingsStateProvider).autoSave, isFalse);
    expect(container.read(settingsStateProvider).requireEditMode, isFalse);
  });

  test('si el guardado o la carga fallan, el estado no cambia', () async {
    final container = createContainer(_FailingSettingsRepository());
    await container.read(getSettingsUseCaseProvider).getSettings();
    await container
        .read(saveSettingsUseCaseProvider)
        .saveSettings(const SettingsEntity(autoSave: false));
    expect(container.read(settingsStateProvider).autoSave, isTrue);
  });

  testWidgets('los switches cambian el estado y lo persisten', (tester) async {
    final container = createContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pump();
    expect(find.byType(SwitchListTile), findsNWidgets(2));

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(container.read(settingsStateProvider).autoSave, isFalse);
    expect(container.read(settingsStateProvider).requireEditMode, isTrue);

    await tester.tap(find.byType(SwitchListTile).last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(container.read(settingsStateProvider).autoSave, isFalse);
    expect(container.read(settingsStateProvider).requireEditMode, isFalse);

    final stored = await tester.runAsync(
      () => SettingsRepositoryImpl().getSettings(),
    );
    expect(stored!.data!.autoSave, isFalse);
    expect(stored.data!.requireEditMode, isFalse);
  });
}
