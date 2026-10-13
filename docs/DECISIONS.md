# DECISIONS — BikeTrack

Settled decisions. Agents must not reopen these. To change one: add a new entry with status "Proposed" and wait for the owner.

| ID | Decision | Reason | Status |
|---|---|---|---|
| D-001 | Flutter UI + Swift native for sensors/background | Develop on Windows; sensors need native control | Accepted |
| D-002 | Activity / Trip / Recording are 3 separate state machines | Handle stops, forgetting, mode change cleanly | Accepted |
| D-003 | Domain logic is pure Dart and returns Commands (no side effects) | Testable on Windows, replayable | Accepted |
| D-004 | Event sourcing: append-only `events` table is source of truth | Rebuild after kills / late wake-ups | Accepted |
| D-005 | Trips contain Segments; totals are derived, never stored as truth | Mixed trips + manual correction | Accepted |
| D-006 | Unknown is a valid result; uncertain parts go to review | Avoid guessing | Accepted |
| D-007 | NFC = user intent for trip start only, NOT an activity signal; manual start always available | NFC proves intent, not motion (C4) | Accepted |
| D-008 | NFC background reading uses Universal Link (custom URL scheme unsupported there) | C2 | Accepted |
| D-009 | Background tracking is not guaranteed; design for recovery + explicit gaps; don't rely on applicationWillTerminate | C1 | Accepted |
| D-010 | Separate `last_received_point` and `last_distance_anchor`; reset anchor after stop/gap | Prevent resume jumps (C3) | Accepted |
| D-011 | Unknown distance stored as null + distance_status (measured/partial/unknown) | 0 ≠ known | Accepted |
| D-012 | HealthKit is last (M5), write cycling workouts only, never steps; track ops in `health_ops` | Avoid duplicates (C5) | Accepted |
| D-013 | M0 feasibility gate before any paid subscription or full build | C6 | Accepted |
| D-014 | All thresholds in Config; initial values are hypotheses | Tuned from field data | Accepted |
| D-015 | Pigeon for Dart↔Swift contract | Typed contract | Accepted |
| D-016 | Antigravity = main implementer; Codex = review/tests/independent tasks; no two agents on same files concurrently | Avoid conflicts | Accepted |
