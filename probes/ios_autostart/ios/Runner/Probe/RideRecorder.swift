import CoreLocation
import Foundation

final class RideRecorder: NSObject, CLLocationManagerDelegate {
  static let shared = RideRecorder()

  enum StartResult {
    case started(rideID: String)
    case failed(String)
  }

  private let manager = CLLocationManager()
  private let defaults = UserDefaults.standard
  private let activeKey = "probe.rideActive"
  private let rideIDKey = "probe.rideID"
  private var pendingStart: (trigger: String, attemptID: String)?
  private var backgroundActivitySession: CLBackgroundActivitySession?
  @available(iOS 18.0, *)
  private var serviceSession: CLServiceSession?

  private override init() {
    super.init()
    manager.delegate = self
  }

  func start(trigger: String, attemptID: String) -> StartResult {
    let status = manager.authorizationStatus
    if status == .denied || status == .restricted {
      ProbeLog.shared.append(event: "start_requested", payload: [
        "trigger": trigger,
        "attempt_id": attemptID,
        "result": "authorization_\(authorizationName(status))",
      ])
      return .failed("location_\(authorizationName(status))")
    }

    let rideID = currentRideID()
    defaults.set(true, forKey: activeKey)
    defaults.set(rideID, forKey: rideIDKey)
    ProbeLog.shared.append(event: "start_requested", payload: [
      "ride_id": rideID,
      "attempt_id": attemptID,
      "trigger": trigger,
    ])
    pendingStart = (trigger, attemptID)

    if status == .notDetermined {
      requestWhenInUse()
    } else {
      configureAndStartUpdates(rideID: rideID)
    }
    return .started(rideID: rideID)
  }

  func stop() {
    let rideID = defaults.string(forKey: rideIDKey) ?? ""
    ProbeLog.shared.append(event: "stop_requested", payload: ["ride_id": rideID])
    // https://developer.apple.com/documentation/corelocation/cllocationmanager/stopupdatinglocation()
    manager.stopUpdatingLocation()
    backgroundActivitySession = nil
    if #available(iOS 18.0, *) {
      serviceSession = nil
    }
    defaults.set(false, forKey: activeKey)
    defaults.removeObject(forKey: rideIDKey)
    pendingStart = nil
    ProbeLog.shared.append(event: "location_updates_stopped", payload: ["ride_id": rideID])
  }

  func recoverIfNeeded() {
    guard defaults.bool(forKey: activeKey), let rideID = defaults.string(forKey: rideIDKey) else { return }
    ProbeLog.shared.append(event: "recovery_attempt", payload: ["ride_id": rideID])
    let status = manager.authorizationStatus
    if status == .denied || status == .restricted {
      ProbeLog.shared.append(event: "recovery_failed", payload: [
        "ride_id": rideID,
        "reason": "location_\(authorizationName(status))",
      ])
      return
    }
    configureAndStartUpdates(rideID: rideID)
  }

  func requestWhenInUse() {
    // https://developer.apple.com/documentation/corelocation/cllocationmanager/requestwheninuseauthorization()
    manager.requestWhenInUseAuthorization()
  }

  func requestAlways() {
    // https://developer.apple.com/documentation/corelocation/cllocationmanager/requestalwaysauthorization()
    manager.requestAlwaysAuthorization()
  }

  func status() -> [String: Any] {
    [
      "recording": defaults.bool(forKey: activeKey),
      "rideId": defaults.string(forKey: rideIDKey) ?? "",
      "locationAuthorization": authorizationName(manager.authorizationStatus),
    ]
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    ProbeLog.shared.append(event: "location_authorization", payload: [
      "status": authorizationName(status),
    ])
    guard let pendingStart else { return }
    if status == .denied || status == .restricted {
      StartGate.shared.fail(rideID: defaults.string(forKey: rideIDKey), attemptID: pendingStart.attemptID, reason: "location_\(authorizationName(status))")
      self.pendingStart = nil
      defaults.set(false, forKey: activeKey)
      return
    }
    guard status != .notDetermined, let rideID = defaults.string(forKey: rideIDKey) else { return }
    configureAndStartUpdates(rideID: rideID)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let rideID = defaults.string(forKey: rideIDKey) ?? ""
    for location in locations {
      let receivedAt = Date()
      let ageMilliseconds = receivedAt.timeIntervalSince(location.timestamp) * 1_000
      let reason: String?
      if location.horizontalAccuracy <= 0 {
        reason = "invalid_accuracy"
      } else if location.horizontalAccuracy > 50 {
        reason = "accuracy_over_50m"
      } else if ageMilliseconds < 0 {
        reason = "future_timestamp"
      } else if ageMilliseconds > 10_000 {
        reason = "stale_over_10s"
      } else {
        reason = nil
      }
      let accepted = reason == nil
      let written = ProbeLog.shared.append(event: "fix", payload: [
        "ride_id": rideID,
        "fix_ts_ms": Int64(location.timestamp.timeIntervalSince1970 * 1_000),
        "recv_ms": Int64(receivedAt.timeIntervalSince1970 * 1_000),
        "h_acc": location.horizontalAccuracy,
        "speed": location.speed,
        "accepted": accepted,
        "reject_reason": reason ?? "",
      ])
      if accepted && written {
        StartGate.shared.acceptedFixWritten(rideID: rideID)
      }
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    let rideID = defaults.string(forKey: rideIDKey)
    ProbeLog.shared.append(event: "location_error", payload: [
      "ride_id": rideID ?? "",
      "error": error.localizedDescription,
    ])
    StartGate.shared.fail(rideID: rideID, attemptID: pendingStart?.attemptID, reason: "location_error")
  }

  private func configureAndStartUpdates(rideID: String) {
    // https://developer.apple.com/documentation/corelocation/cllocationmanager/allowsbackgroundlocationupdates
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
    manager.activityType = .fitness
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.showsBackgroundLocationIndicator = true
    if #available(iOS 17.0, *) {
      // https://developer.apple.com/documentation/corelocation/clbackgroundactivitysession
      backgroundActivitySession = CLBackgroundActivitySession()
    }
    if #available(iOS 18.0, *) {
      // https://developer.apple.com/documentation/corelocation/clservicesession
      serviceSession = CLServiceSession(authorization: .always)
    }
    // https://developer.apple.com/documentation/corelocation/cllocationmanager/startupdatinglocation()
    manager.startUpdatingLocation()
    ProbeLog.shared.append(event: "location_updates_started", payload: ["ride_id": rideID])
  }

  private func currentRideID() -> String {
    if defaults.bool(forKey: activeKey), let rideID = defaults.string(forKey: rideIDKey), !rideID.isEmpty {
      return rideID
    }
    return UUID().uuidString
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
}
