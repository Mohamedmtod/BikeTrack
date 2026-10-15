import Flutter
import UIKit

@main
@objc @MainActor class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ProbeLog.shared.append(event: "launch", payload: [
      "launch_option_keys": launchOptions?.keys.map(\.rawValue) ?? [],
    ])
    RideRecorder.shared.recoverIfNeeded()
    NotificationPermission.shared.requestIfNeeded()
    NotificationCenter.default.addObserver(
      forName: UIApplication.didReceiveMemoryWarningNotification,
      object: nil,
      queue: .main
    ) { _ in
      ProbeLog.shared.append(event: "memory_warning")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    ProbeURLHandler.handle(url)
    return super.application(app, open: url, options: options)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    ProbeLog.shared.append(event: "application_background")
    super.applicationDidEnterBackground(application)
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    ProbeLog.shared.append(event: "application_foreground")
    super.applicationWillEnterForeground(application)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    ProbeLog.shared.append(event: "will_terminate")
    super.applicationWillTerminate(application)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

@MainActor
enum ProbeURLHandler {
  static func handle(_ url: URL) {
    guard url.scheme == "biketrack", url.host == "start-ride" else { return }
    let attemptID = UUID().uuidString
    ProbeLog.shared.append(event: "url_received", payload: [
      "attempt_id": attemptID,
      "url": url.absoluteString,
    ])
    switch RideRecorder.shared.start(trigger: "url", attemptID: attemptID) {
    case let .started(rideID):
      StartGate.shared.begin(rideID: rideID, attemptID: attemptID) { _ in }
    case let .failed(reason):
      NotificationPermission.shared.postFailure(rideID: nil, attemptID: attemptID, reason: reason) { scheduled in
        ProbeLog.shared.append(event: "notify_failure", payload: [
          "attempt_id": attemptID,
          "reason": reason,
          "scheduled": scheduled,
        ])
      }
    }
  }
}
