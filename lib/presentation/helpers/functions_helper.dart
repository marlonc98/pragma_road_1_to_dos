import 'dart:async';

class FunctionsHelper {
  static Timer? resetSearch({
    required Function() searchFunction,
    Timer? timer,
    Duration delay = const Duration(milliseconds: 500),
  }) {
    timer?.cancel();
    return Timer(delay, () {
      searchFunction();
    });
  }
}
