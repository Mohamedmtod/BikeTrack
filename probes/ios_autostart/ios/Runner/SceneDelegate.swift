import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var probeChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    ProbeLog.shared.append(event: "scene_connected")
    for context in connectionOptions.urlContexts {
      ProbeURLHandler.handle(context.url)
    }
    installProbeChannel()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    ProbeLog.shared.append(event: "scene_active")
    super.sceneDidBecomeActive(scene)
  }

  override func sceneDidEnterBackground(_ scene: UIScene) {
    ProbeLog.shared.append(event: "scene_background")
    super.sceneDidEnterBackground(scene)
  }

  override func sceneWillEnterForeground(_ scene: UIScene) {
    ProbeLog.shared.append(event: "scene_foreground")
    super.sceneWillEnterForeground(scene)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      ProbeURLHandler.handle(context.url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }

  private func installProbeChannel() {
    guard probeChannel == nil,
          let flutterViewController = window?.rootViewController as? FlutterViewController
    else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "biketrack/probe",
      binaryMessenger: flutterViewController.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    probeChannel = channel
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "status":
      var response = RideRecorder.shared.status()
      NotificationPermission.shared.status { status in
        response["notificationAuthorization"] = status
        DispatchQueue.main.async { result(response) }
      }
    case "start":
      let attemptID = UUID().uuidString
      switch RideRecorder.shared.start(trigger: "flutter", attemptID: attemptID) {
      case let .started(rideID):
        StartGate.shared.begin(rideID: rideID, attemptID: attemptID) { _ in }
        result(["started": true, "rideId": rideID])
      case let .failed(reason):
        NotificationPermission.shared.postFailure(rideID: nil, attemptID: attemptID, reason: reason) { scheduled in
          ProbeLog.shared.append(event: "notify_failure", payload: [
            "attempt_id": attemptID,
            "reason": reason,
            "scheduled": scheduled,
          ])
        }
        result(FlutterError(code: "start_failed", message: reason, details: nil))
      }
    case "stop":
      RideRecorder.shared.stop()
      result(nil)
    case "readLogTail":
      let arguments = call.arguments as? [String: Any]
      let count = arguments?["count"] as? Int ?? 30
      result(ProbeLog.shared.readTail(min(max(count, 1), 200)))
    case "clearLog":
      let cleared = ProbeLog.shared.clear()
      if cleared {
        ProbeLog.shared.append(event: "log_cleared")
      }
      result(cleared)
    case "requestWhenInUse":
      RideRecorder.shared.requestWhenInUse()
      result(nil)
    case "requestAlways":
      RideRecorder.shared.requestAlways()
      result(nil)
    case "requestNotifications":
      NotificationPermission.shared.request { granted in
        DispatchQueue.main.async { result(granted) }
      }
    case "shareLog":
      shareLog(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func shareLog(result: @escaping FlutterResult) {
    guard let fileURL = ProbeLog.shared.shareURL(),
          FileManager.default.fileExists(atPath: fileURL.path),
          let presenter = window?.rootViewController
    else {
      result(FlutterError(code: "log_missing", message: "No probe log is available.", details: nil))
      return
    }
    // https://developer.apple.com/documentation/uikit/uiactivityviewcontroller
    let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    if let popover = activityController.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = presenter.view.bounds
    }
    presenter.present(activityController, animated: true) {
      result(nil)
    }
  }
}
