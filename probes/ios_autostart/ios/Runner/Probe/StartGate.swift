import Foundation

enum StartGateOutcome {
  case started
  case failed(String)
}

final class StartGate {
  static let shared = StartGate()

  private struct PendingAttempt {
    let rideID: String
    let attemptID: String
    let completion: (StartGateOutcome) -> Void
    let timeout: DispatchWorkItem
  }

  private let queue = DispatchQueue(label: "com.mohamedmtod.biketrack.start-gate")
  private var pending: PendingAttempt?

  private init() {}

  func waitForFirstAcceptedFix(rideID: String, attemptID: String) async -> StartGateOutcome {
    await withCheckedContinuation { continuation in
      begin(rideID: rideID, attemptID: attemptID) { outcome in
        continuation.resume(returning: outcome)
      }
    }
  }

  func begin(rideID: String, attemptID: String, completion: @escaping (StartGateOutcome) -> Void) {
    queue.async {
      self.completePendingLocked(with: .failed("superseded"), notify: false)
      let timeout = DispatchWorkItem { [weak self] in
        self?.fail(rideID: rideID, attemptID: attemptID, reason: "timeout")
      }
      self.pending = PendingAttempt(
        rideID: rideID,
        attemptID: attemptID,
        completion: completion,
        timeout: timeout
      )
      self.queue.asyncAfter(deadline: .now() + 20, execute: timeout)
    }
  }

  func acceptedFixWritten(rideID: String) {
    queue.async {
      guard let pending = self.pending, pending.rideID == rideID else { return }
      pending.timeout.cancel()
      self.pending = nil
      NotificationPermission.shared.postSuccess(rideID: pending.rideID, attemptID: pending.attemptID) { scheduled in
        guard scheduled else {
          ProbeLog.shared.append(event: "notify_failure", payload: [
            "ride_id": pending.rideID,
            "attempt_id": pending.attemptID,
            "reason": "notification_schedule_failed",
          ])
          pending.completion(.failed("notification_schedule_failed"))
          return
        }

        let auditWritten = ProbeLog.shared.append(event: "notify_success", payload: [
          "ride_id": pending.rideID,
          "attempt_id": pending.attemptID,
        ])
        guard auditWritten else {
          ProbeLog.shared.append(event: "notify_success_audit_write_failed", payload: [
            "ride_id": pending.rideID,
            "attempt_id": pending.attemptID,
          ])
          pending.completion(.failed("notify_success_audit_write_failed"))
          return
        }
        pending.completion(.started)
      }
    }
  }

  func fail(rideID: String?, attemptID: String?, reason: String) {
    queue.async {
      guard let pending = self.pending,
            (rideID == nil || pending.rideID == rideID),
            (attemptID == nil || pending.attemptID == attemptID)
      else {
        return
      }
      self.completePendingLocked(with: .failed(reason), notify: true)
    }
  }

  private func completePendingLocked(with outcome: StartGateOutcome, notify: Bool) {
    guard let pending else { return }
    pending.timeout.cancel()
    self.pending = nil
    guard notify else {
      pending.completion(outcome)
      return
    }

    let reason: String
    if case let .failed(value) = outcome {
      reason = value
    } else {
      reason = "unknown"
    }
    ProbeLog.shared.append(event: "start_gate_failure", payload: [
      "ride_id": pending.rideID,
      "attempt_id": pending.attemptID,
      "reason": reason,
    ])
    NotificationPermission.shared.postFailure(
      rideID: pending.rideID,
      attemptID: pending.attemptID,
      reason: reason
    ) { scheduled in
      ProbeLog.shared.append(event: "notify_failure", payload: [
        "ride_id": pending.rideID,
        "attempt_id": pending.attemptID,
        "reason": reason,
        "scheduled": scheduled,
      ])
      pending.completion(outcome)
    }
  }
}
