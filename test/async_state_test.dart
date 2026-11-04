import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';

void main() {
  group('errores posibles', () {
    test('sin conexión, por excepción o por texto', () {
      expect(
        AsyncState.fromError(const SocketException('x')).error,
        ErrorsConstants.noInternet,
      );
      expect(
        AsyncState.fromError('Operation timed out').error,
        ErrorsConstants.noInternet,
      );
      expect(
        AsyncState.fromError(ErrorsConstants.noInternet).error,
        ErrorsConstants.noInternet,
      );
    });

    test('tiempo agotado', () {
      expect(
        AsyncState.fromError(ErrorsConstants.timeout).error,
        ErrorsConstants.timeout,
      );
    });

    test('una clave conocida se conserva', () {
      expect(
        AsyncState.fromError(ErrorsConstants.emptyNote).error,
        ErrorsConstants.emptyNote,
      );
    });

    test('un texto desconocido usa el error por defecto si lo hay', () {
      expect(AsyncState.fromError('raro').error, 'raro');
      expect(AsyncState.fromError('raro', defaultError: 'otro').error, 'otro');
    });

    test('una excepción sin mensaje es un error desconocido', () {
      expect(
        AsyncState.fromError(Exception()).error,
        ErrorsConstants.unknownError,
      );
      expect(
        AsyncState.fromError(Exception(), defaultError: 'otro').error,
        'otro',
      );
    });

    test(
      'un Error de Dart, o cualquier otro tipo, es un error desconocido',
      () {
        for (final error in [TypeError(), StateError('x'), 5, null]) {
          expect(
            AsyncState.fromError(error).error,
            ErrorsConstants.unknownError,
            reason: '$error',
          );
          expect(
            AsyncState.fromError(error, defaultError: 'otro').error,
            'otro',
            reason: '$error',
          );
        }
      },
    );

    test('siempre queda en estado de error y sin datos', () {
      final state = AsyncState<int>.fromError(Exception());
      expect(state.isError, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.data, isNull);
    });
  });

  group('vacíos', () {
    test('success sin datos es éxito con data null', () {
      final state = AsyncState<int>.success();
      expect(state.isSuccess, isTrue);
      expect(state.data, isNull);
      expect(state.error, isNull);
    });

    test('map con data null no llama a la función', () {
      final state = AsyncState<int>.success().map((value) => value * 2);
      expect(state.isSuccess, isTrue);
      expect(state.data, isNull);
    });

    test('map de un error conserva el error y no transforma', () {
      final state = AsyncState<int>.fromError(ErrorsConstants.noteNotFound)
          .map((value) => value * 2);
      expect(state.isError, isTrue);
      expect(state.error, ErrorsConstants.noteNotFound);
    });
  });

  test('copyWith conserva lo que no se indica', () {
    final state = AsyncState<int>.success(data: 1);
    final loading = state.copyWith(status: PetitionStatus.loading);
    expect(loading.isLoading, isTrue);
    expect(loading.data, 1);
  });

  test('map transforma los datos', () {
    expect(AsyncState.success(data: 2).map((value) => value * 2).data, 4);
  });
}
