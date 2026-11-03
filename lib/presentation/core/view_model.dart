import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ViewModel<T> with ChangeNotifier {
  T widget;
  BuildContext context;
  WidgetRef ref;
  bool Function() isMounted;
  bool _isDisposed = false;
  bool get mounted => isMounted();

  ViewModel({
    required this.context,
    required this.widget,
    required this.ref,
    bool Function()? isMounted,
  }) : isMounted = isMounted ?? (() => true);

  @override
  notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
