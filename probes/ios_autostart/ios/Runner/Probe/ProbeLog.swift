import Foundation

final class ProbeLog {
  static let shared = ProbeLog()

  private let queue = DispatchQueue(label: "com.mohamedmtod.biketrack.probe-log")
  private let fileManager = FileManager.default
  private var nextSequence: Int64

  private init() {
    nextSequence = 1
    queue.sync {
      nextSequence = lastSequence() + 1
    }
  }

  // https://developer.apple.com/documentation/foundation/filemanager/urls(for:in:)
  private var fileURL: URL? {
    fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
      .appendingPathComponent("probe_log.jsonl")
  }

  @discardableResult
  func append(event: String, payload: [String: Any] = [:]) -> Bool {
    queue.sync {
      guard let fileURL, JSONSerialization.isValidJSONObject(payload) else {
        return false
      }

      let record: [String: Any] = [
        "seq": nextSequence,
        "wall_ms": Int64(Date().timeIntervalSince1970 * 1_000),
        "uptime_ms": Int64(ProcessInfo.processInfo.systemUptime * 1_000),
        "event": event,
        "payload": payload,
      ]
      guard let json = try? JSONSerialization.data(withJSONObject: record),
            var line = String(data: json, encoding: .utf8)?.data(using: .utf8)
      else {
        return false
      }
      line.append(0x0A)

      do {
        if !fileManager.fileExists(atPath: fileURL.path) {
          guard fileManager.createFile(atPath: fileURL.path, contents: nil) else {
            return false
          }
        }
        // https://developer.apple.com/documentation/foundation/filehandle
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
        try handle.synchronize()
        nextSequence += 1
        return true
      } catch {
        return false
      }
    }
  }

  func shareURL() -> URL? {
    queue.sync { fileURL }
  }

  func readTail(_ count: Int) -> [String] {
    queue.sync {
      guard count > 0, let fileURL, let data = try? Data(contentsOf: fileURL),
            let text = String(data: data, encoding: .utf8)
      else {
        return []
      }
      return text.split(separator: "\n", omittingEmptySubsequences: true).suffix(count).map(String.init)
    }
  }

  @discardableResult
  func clear() -> Bool {
    queue.sync {
      guard let fileURL else { return false }
      do {
        if fileManager.fileExists(atPath: fileURL.path) {
          try fileManager.removeItem(at: fileURL)
        }
        guard fileManager.createFile(atPath: fileURL.path, contents: nil) else {
          return false
        }
        nextSequence = 1
        return true
      } catch {
        return false
      }
    }
  }

  private func lastSequence() -> Int64 {
    guard let fileURL, let data = try? Data(contentsOf: fileURL),
          let text = String(data: data, encoding: .utf8)
    else {
      return 0
    }

    return text.split(separator: "\n").reduce(0) { highest, line in
      guard let data = line.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let sequence = object["seq"] as? NSNumber
      else {
        return highest
      }
      return max(highest, sequence.int64Value)
    }
  }
}
