# ARCHITECTURE — BikeTrack (summary)

Full detail: `ENGINEERING_PLAN.md` §3–§11.

## Layers
| Layer | Location | Rule |
|---|---|---|
| Domain (pure Dart) | `lib/domain/` | No Flutter, no I/O. State machines, GPS filter, geo, classifier. Fully testable on Windows. |
| Data | `lib/data/` | drift (SQLite). Events table is append-only. |
| App | `lib/app/` | Riverpod controllers. Executes Commands returned by the domain. |
| UI | `lib/ui/`, `lib/debug/` | Screens, review, debug + CSV export. |
| Bridge | `lib/bridge/` + `ios/Runner/Bridge/` | Pigeon-generated typed API. |
| iOS native | `ios/Runner/Services/` | MotionService, LocationService, NfcService, HealthService (Swift). |

## Three separate state machines
1. Activity: stationary / walking / running / cycling / automotive / unknown.
2. Trip: idle → pending → active ⇄ paused → suspectedForgotten → completed / autoClosed / needsReview / cancelled.
3. Recording: off / lowPower / highAccuracy.

## Core flow
Sensor → Swift → (write immediately) → EventChannel → events table
→ ActivityClassifier → TripStateMachine(event, state) → (newState, commands) → App executes commands.

## Distance rules (non-negotiable)
- Distance only from accepted GPS points while not stationary (§7.2).
- Two references: `last_received_point` vs `last_distance_anchor`; anchor resets after stop/gap/segment change/relaunch.
- Unknown distance = `null` + `distance_status`, never 0.
