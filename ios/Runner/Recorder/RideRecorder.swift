import CoreLocation
import Foundation

@MainActor
final class RideRecorder: NSObject, CLLocationManagerDelegate, RecorderHostApi {
  static let shared = RideRecorder()

  private let manager = CLLocationManager()
  private var flutterApi: RecorderFlutterApi?
  private var rideId: String?
  private var pendingStart = false

  private override init() {
    super.init()
    manager.delegate = self
  }

  func connect(flutterApi: RecorderFlutterApi) {
    self.flutterApi = flutterApi
  }

  func start(trigger: String, attemptId: String) throws -> RecorderStartResult {
    let authorization = manager.authorizationStatus
    guard authorization != .denied, authorization != .restricted else {
      return RecorderStartResult(
        started: false,
        rideId: nil,
        reason: "location_\(authorizationName(authorization))"
      )
    }

    let rideId = self.rideId ?? UUID().uuidString
    self.rideId = rideId
    pendingStart = true

    if authorization == .notDetermined {
      manager.requestWhenInUseAuthorization()
    } else {
      startLocationUpdates(rideId: rideId)
    }

    return RecorderStartResult(started: true, rideId: rideId, reason: nil)
  }

  func stop() throws {
    let rideId = rideId
    manager.stopUpdatingLocation()
    self.rideId = nil
    pendingStart = false
    sendLocationUpdate(started: false, rideId: rideId)
  }

  func status() throws -> RecorderStatus {
    RecorderStatus(
      recording: rideId != nil,
      rideId: rideId,
      authorization: authorizationName(manager.authorizationStatus)
    )
  }

  func requestWhenInUse() throws {
    manager.requestWhenInUseAuthorization()
  }

  func requestAlways() throws {
    manager.requestAlwaysAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let authorization = manager.authorizationStatus
    flutterApi?.onAuthorizationChanged(
      change: RecorderAuthorizationChange(authorization: authorizationName(authorization))
    ) { _ in }

    guard pendingStart else { return }
    guard authorization != .notDetermined else { return }
    guard authorization != .denied, authorization != .restricted, let rideId else {
      self.rideId = nil
      pendingStart = false
      return
    }
    startLocationUpdates(rideId: rideId)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let recvMs = Int64(Date().timeIntervalSince1970 * 1_000)
    for location in locations {
      flutterApi?.onRawFix(
        fix: NativeGpsFix(
          latitudeDeg: location.coordinate.latitude,
          longitudeDeg: location.coordinate.longitude,
          fixTsMs: Int64(location.timestamp.timeIntervalSince1970 * 1_000),
          hAccuracyM: location.horizontalAccuracy,
          recvMs: recvMs,
          rideId: rideId
        )
      ) { _ in }
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    flutterApi?.onLocationError(
      error: RecorderLocationError(
        code: locationErrorCode(error),
        message: error.localizedDescription,
        rideId: rideId
      )
    ) { _ in }
  }

  private func startLocationUpdates(rideId: String) {
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
    manager.activityType = .fitness
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.showsBackgroundLocationIndicator = true
    manager.startUpdatingLocation()
    pendingStart = false
    sendLocationUpdate(started: true, rideId: rideId)
  }

  private func sendLocationUpdate(started: Bool, rideId: String?) {
    flutterApi?.onLocationUpdate(
      update: RecorderLocationUpdate(started: started, rideId: rideId)
    ) { _ in }
  }

  private func authorizationName(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    case .denied: return "denied"
    case .authorizedAlways: return "always"
    case .authorizedWhenInUse: return "whenInUse"
    @unknown default: return "unknown"
    }
  }

  private func locationErrorCode(_ error: Error) -> String {
    guard let locationError = error as? CLError else { return "unknown" }
    return String(describing: locationError.code)
  }
}
