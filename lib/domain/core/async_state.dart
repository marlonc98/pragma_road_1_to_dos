import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';

enum PetitionStatus { notStarted, loading, complete, failed }

class AsyncState<T> {
  PetitionStatus status;
  T? data;
  String? error;

  AsyncState({
    this.status = PetitionStatus.loading,
    this.data,
    this.error,
  });

  AsyncState.notStarted() : status = PetitionStatus.notStarted;

  factory AsyncState.success({T? data}) {
    return AsyncState(status: PetitionStatus.complete, data: data);
  }

  factory AsyncState.loading() {
    return AsyncState(status: PetitionStatus.loading);
  }

  factory AsyncState.fromError(
    dynamic error, {
    String? defaultError,
  }) {
    String? errorGetted;
    if (error.toString().contains("Operation timed out") ||
        error.toString().contains("SocketException") ||
        error.toString().contains(ErrorsConstants.noInternet)) {
      errorGetted = ErrorsConstants.noInternet;
    } else if (error.toString().contains(ErrorsConstants.timeout)) {
      errorGetted = ErrorsConstants.timeout;
    } else if (error is String) {
      errorGetted = error;
      if (!ErrorsConstants.existsKey(error)) {
        errorGetted = defaultError ?? error;
      }
    } else if (error is Exception) {
      if (error.toString() == Exception().toString()) {
        errorGetted = defaultError ?? ErrorsConstants.unknownError;
      } else {
        errorGetted = error.toString();
      }
    }
    return AsyncState(
      status: PetitionStatus.failed,
      error: errorGetted,
    );
  }

  bool get isSuccess => status == PetitionStatus.complete;
  bool get isError => status == PetitionStatus.failed;
  bool get isLoading => status == PetitionStatus.loading;
  bool get isNotStarted => status == PetitionStatus.notStarted;

  AsyncState changeStatus(PetitionStatus status) {
    return AsyncState(status: status, data: data, error: error);
  }

  AsyncState setLoading() {
    return changeStatus(PetitionStatus.loading);
  }

  @override
  String toString() {
    return 'AsyncState{status: $status, data: $data, error: $error}';
  }

  AsyncState<T> copyWith({
    PetitionStatus? status,
    T? data,
    String? error,
  }) {
    return AsyncState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  AsyncState<R> map<R>(R Function(T) transform) {
    if (isError) {
      return AsyncState<R>(status: status, error: error);
    }
    return AsyncState<R>(
      status: status,
      data: data != null ? transform(data as T) : null,
      error: error,
    );
  }
}
