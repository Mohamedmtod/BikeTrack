import Flutter
import UIKit

@main
@objc @MainActor class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BikeTrackRecorder")!
    let flutterApi = RecorderFlutterApi(binaryMessenger: registrar.messenger())
    RideRecorder.shared.connect(flutterApi: flutterApi)
    RecorderHostApiSetup.setUp(
      binaryMessenger: registrar.messenger(),
      api: RideRecorder.shared
    )
  }
}
