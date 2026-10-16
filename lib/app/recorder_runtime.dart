import 'package:flutter/foundation.dart';

enum RecorderActivity { idle, starting, recording, stopping }

class RecorderRuntime extends ChangeNotifier {
  RecorderActivity activity = RecorderActivity.idle;
  String? latestPersistenceError;
  String? latestNativeError;
  int persistedCallbackCount = 0;

  void setActivity(RecorderActivity value) {
    activity = value;
    notifyListeners();
  }

  void persistenceFailed(String operation, Object error) {
    latestPersistenceError = '$operation: $error';
    notifyListeners();
  }

  void nativeFailed(String operation, Object error) {
    latestNativeError = '$operation: $error';
    notifyListeners();
  }

  void callbackPersisted() {
    persistedCallbackCount++;
    notifyListeners();
  }
}
