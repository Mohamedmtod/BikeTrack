import 'package:flutter/foundation.dart';

import '../data/events/event_record.dart';

enum RecorderActivity { idle, starting, recording, stopping }

enum ProjectionDrainState { idle, draining, blocked }

class RecorderRuntime extends ChangeNotifier {
  RecorderActivity activity = RecorderActivity.idle;
  String? latestPersistenceError;
  String? latestNativeError;
  int persistedCallbackCount = 0;
  ProjectionDrainState projectionState = ProjectionDrainState.idle;
  StoredEvent? blockingProjectionEvent;
  String? latestProjectionError;

  void projectionStarted() {
    projectionState = ProjectionDrainState.draining;
    blockingProjectionEvent = null;
    latestProjectionError = null;
    notifyListeners();
  }

  void projectionCompleted() {
    projectionState = ProjectionDrainState.idle;
    notifyListeners();
  }

  void projectionFailed(StoredEvent? event, Object error) {
    projectionState = ProjectionDrainState.blocked;
    blockingProjectionEvent = event;
    latestProjectionError = '$error';
    notifyListeners();
  }

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
