import AppIntents
import Foundation
import UIKit

struct StartRideForegroundIntent: AppIntent {
  static var title: LocalizedStringResource = "Start Ride (open app)"
  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult & ProvidesDialog {
    try await ProbeIntentRunner.run(variant: "foreground")
    return .result(dialog: "Ride recording started")
  }
}

struct StartRideBackgroundIntent: AppIntent {
  static var title: LocalizedStringResource = "Start Ride (background)"
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

  func perform() async throws -> some IntentResult & ProvidesDialog {
    try await ProbeIntentRunner.run(variant: "background")
    return .result(dialog: "Ride recording started")
  }
}

struct BikeTrackShortcuts: AppShortcutsProvider {
  static var shortcutTileColor: ShortcutTileColor = .blue

  static var appShortcuts: [AppShortcut] {
    [
      AppShortcut(
        intent: StartRideForegroundIntent(),
        phrases: ["Start a ride in \(.applicationName)"],
        shortTitle: "Start Ride",
        systemImageName: "bicycle"
      ),
      AppShortcut(
        intent: StartRideBackgroundIntent(),
        phrases: ["Start a background ride in \(.applicationName)"],
        shortTitle: "Start Background Ride",
        systemImageName: "bicycle"
      ),
    ]
  }
}

enum ProbeIntentError: LocalizedError {
  case startFailed(String)

  var errorDescription: String? {
    switch self {
    case let .startFailed(reason): return "BikeTrack couldn't start the ride: \(reason)."
    }
  }
}

enum ProbeIntentRunner {
  static func run(variant: String) async throws {
    let attemptID = UUID().uuidString
    let recorderStatus = RideRecorder.shared.status()
    // https://developer.apple.com/documentation/uikit/uiapplication/applicationstate
    ProbeLog.shared.append(event: "intent_invoked", payload: [
      "variant": variant,
      "attempt_id": attemptID,
      "application_state": UIApplication.shared.applicationState.rawValue,
      "protected_data_available": UIApplication.shared.isProtectedDataAvailable,
      "location_authorization": recorderStatus["locationAuthorization"] ?? "unknown",
    ])

    switch RideRecorder.shared.start(trigger: "intent_\(variant)", attemptID: attemptID) {
    case let .started(rideID):
      let outcome = await StartGate.shared.waitForFirstAcceptedFix(rideID: rideID, attemptID: attemptID)
      if case let .failed(reason) = outcome {
        throw ProbeIntentError.startFailed(reason)
      }
    case let .failed(reason):
      NotificationPermission.shared.postFailure(rideID: nil, attemptID: attemptID, reason: reason) { scheduled in
        ProbeLog.shared.append(event: "notify_failure", payload: [
          "attempt_id": attemptID,
          "reason": reason,
          "scheduled": scheduled,
        ])
      }
      throw ProbeIntentError.startFailed(reason)
    }
  }
}
