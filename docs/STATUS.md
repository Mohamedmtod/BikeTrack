# STATUS — BikeTrack

- Completed: T-018 automatic single-flight raw-event projection with startup drain and insertion-ID ordering (D-034).
- Projection errors block the first failing event without blocking raw writes/native controls; runtime/debug show the event, error, pending state and explicit retry.
- T-017 transactional snapshots and idempotent processing remain unchanged; targeted format and full format check clean, `flutter analyze` clean, `flutter test` passed (193 tests).
- iOS build and iPhone native/debug UI behavior remain unverified on Windows; owner device verification is needed.
