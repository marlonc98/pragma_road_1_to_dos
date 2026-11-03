import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/data/repositories/localization/localization_repository_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_mock.dart';
import 'package:gestor_tareas_personales/domain/repositories/localization_repository.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';
import 'package:gestor_tareas_personales/domain/use_cases/load_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/delete_note_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/get_notes_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/get_pinned_notes_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/pin_note_use_case.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/save_note_use_case.dart';
import 'package:gestor_tareas_personales/flavors/flavors.dart';
import 'package:gestor_tareas_personales/presentation/states/localization_state_impl.dart';

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
//#endregion repositories

//#region ------------- States -------------------------//
final localizationStateProvider =
    NotifierProvider<LocalizationStateImpl, Map<String, String>>(
      LocalizationStateImpl.new,
    );
//#endregion ---------- States ------------------------//

//#region ------------- use cases -------------------------//
final loadUseCaseProvider = Provider<LoadUseCase>(
  (ref) => LoadUseCase(
    localizationState: ref.read(localizationStateProvider.notifier),
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
//#endregion ---------- use cases -------------------------//
