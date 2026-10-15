import Foundation
import UserNotifications

final class NotificationPermission {
  static let shared = NotificationPermission()

  private let requestedKey = "probe.notificationPermissionRequested"

  private init() {}

  func requestIfNeeded() {
    guard !UserDefaults.standard.bool(forKey: requestedKey) else { return }
    UserDefaults.standard.set(true, forKey: requestedKey)
    request { _ in }
  }

  func request(completion: @escaping (Bool) -> Void) {
    // https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
      ProbeLog.shared.append(event: "notification_authorization", payload: [
        "granted": granted,
        "error": error?.localizedDescription ?? "",
      ])
      completion(granted)
    }
  }

  func status(completion: @escaping (String) -> Void) {
    // https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/notificationsettings()
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      completion(Self.statusName(settings.authorizationStatus))
    }
  }

  func postSuccess(rideID: String, attemptID: String, completion: @escaping (Bool) -> Void) {
    schedule(
      title: "BikeTrack",
      body: "Ride recording started",
      userInfo: ["ride_id": rideID, "attempt_id": attemptID],
      completion: completion
    )
  }

  func postFailure(rideID: String?, attemptID: String?, reason: String, completion: @escaping (Bool) -> Void) {
    var userInfo: [String: String] = ["reason": reason]
    if let rideID { userInfo["ride_id"] = rideID }
    if let attemptID { userInfo["attempt_id"] = attemptID }
    schedule(
      title: "BikeTrack",
      body: "Couldn't start ride. Tap to start.",
      userInfo: userInfo,
      completion: completion
    )
  }

  private func schedule(
    title: String,
    body: String,
    userInfo: [String: String],
    completion: @escaping (Bool) -> Void
  ) {
    // https://developer.apple.com/documentation/usernotifications/unmutableusernotificationcontent
    let content = UNMutableUserNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.userInfo = userInfo
    // https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/add(_:withcompletionhandler:)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { error in
      completion(error == nil)
    }
  }

  private static func statusName(_ status: UNAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .authorized: return "authorized"
    case .provisional: return "provisional"
    case .ephemeral: return "ephemeral"
    @unknown default: return "unknown"
    }
  }
}
