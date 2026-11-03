import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/data/repositories/localization/localization_repository_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_mock.dart';
import 'package:gestor_tareas_personales/data/repositories/settings/settings_repository_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/settings/settings_repository_mock.dart';
import 'package:gestor_tareas_personales/domain/repositories/localization_repository.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';
import 'package:gestor_tareas_personales/domain/repositories/settings_repository.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/use_cases/settings/get_settings_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/settings/save_settings_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/load_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/delete_note_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/get_notes_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/get_pinned_notes_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/pin_note_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/save_note_use_case.dart';
import 'package:gestor_tareas_personales/flavors/flavors.dart';
import 'package:gestor_tareas_personales/presentation/states/localization_state_impl.dart';
import 'package:gestor_tareas_personales/presentation/states/settings_state_impl.dart';

//#region ------------- repositories -------------------------//
final localizationRepositoryProvider = Provider<LocalizationRepository>(
  (ref) => LocalizationRepositoryImpl(),
);
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => switch (F.appFlavor) {
    Flavor.mock => NoteRepositoryMock(),
    Flavor.dev || Flavor.prod => NoteRepositoryImpl(),
  },
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => switch (F.appFlavor) {
    Flavor.mock => SettingsRepositoryMock(),
    Flavor.dev || Flavor.prod => SettingsRepositoryImpl(),
  },
);
//#endregion repositories

//#region ------------- States -------------------------//
final localizationStateProvider =
    NotifierProvider<LocalizationStateImpl, Map<String, String>>(
      LocalizationStateImpl.new,
    );
final settingsStateProvider =
    NotifierProvider<SettingsStateImpl, SettingsEntity>(SettingsStateImpl.new);
//#endregion ---------- States ------------------------//

//#region ------------- use cases -------------------------//
final loadUseCaseProvider = Provider<LoadUseCase>(
  (ref) => LoadUseCase(
    localizationState: ref.read(localizationStateProvider.notifier),
    getSettingsUseCase: ref.read(getSettingsUseCaseProvider),
  ),
);
//#region ------------- note -------------------------//
final getNotesUseCaseProvider = Provider<GetNotesUseCase>(
  (ref) => GetNotesUseCase(noteRepository: ref.read(noteRepositoryProvider)),
);
final getPinnedNotesUseCaseProvider = Provider<GetPinnedNotesUseCase>(
  (ref) =>
      GetPinnedNotesUseCase(noteRepository: ref.read(noteRepositoryProvider)),
);
final saveNoteUseCaseProvider = Provider<SaveNoteUseCase>(
  (ref) => SaveNoteUseCase(noteRepository: ref.read(noteRepositoryProvider)),
);
final deleteNoteUseCaseProvider = Provider<DeleteNoteUseCase>(
  (ref) => DeleteNoteUseCase(noteRepository: ref.read(noteRepositoryProvider)),
);
final pinNoteUseCaseProvider = Provider<PinNoteUseCase>(
  (ref) => PinNoteUseCase(noteRepository: ref.read(noteRepositoryProvider)),
);
//#endregion ---------- note -------------------------//
//#region ------------- settings -------------------------//
final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>(
  (ref) => GetSettingsUseCase(
    settingsRepository: ref.read(settingsRepositoryProvider),
    settingsState: ref.read(settingsStateProvider.notifier),
  ),
);
final saveSettingsUseCaseProvider = Provider<SaveSettingsUseCase>(
  (ref) => SaveSettingsUseCase(
    settingsRepository: ref.read(settingsRepositoryProvider),
    settingsState: ref.read(settingsStateProvider.notifier),
  ),
);
//#endregion ---------- settings -------------------------//
//#endregion ---------- use cases -------------------------//
