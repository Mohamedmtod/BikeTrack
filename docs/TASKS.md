# TASKS — BikeTrack

Rules: one owner per task; only "Allowed files" may change; branch `task/<ID>-<name>`.

## Task template
```
### T-XXX — <title>
Owner: Antigravity | Codex
Status: todo | in-progress | review | done
Branch: task/T-XXX-<name>
Plan refs: §x.y
Goal: <1–2 lines>
Allowed files: <paths/globs>
Forbidden: everything else
Steps: <short list>
Tests required: <list>
Acceptance criteria: <checkable list>
Reviewer: <other agent or owner>
```

---

### T-020 — Live rides, routes, and derived distance UI
Owner: Claude Code CLI
Status: in-progress
Branch: task/T-020-live-rides-ui
Plan refs: D-033–D-036, §5.2–§5.4, §6.4, §7.1–§7.2
Goal: Personal manual ride home, projected live MapKit route, derived reliable distances, terminal ride history and detail; debug/export remains accessible.
Allowed files: `lib/main.dart`, `lib/app/{recorder_runtime.dart,recorder_session.dart,projection_drain_coordinator.dart}`, `lib/bridge/{recorder_api.dart,recorder_bridge.dart,generated/recorder.g.dart}`, `lib/data/database/{app_database.dart,app_database.g.dart}`, `lib/data/events/event_repository.dart`, `lib/data/projection/projection_state_repository.dart`, `lib/data/trips/**`, `lib/presentation/**`, `lib/ui/**`, `lib/debug/recorder_debug_screen.dart`, `pigeons/recorder.dart`, `ios/Runner/{AppDelegate.swift,Generated/Recorder.g.swift,Recorder/**}`, `test/bridge/**`, `test/data/trips/**`, `test/presentation/**`, `test/widget_test.dart`, `test/app/recorder_test_fakes.dart`, `test/helpers/**` (only shared route fixtures), `docs/{CODEMAP.md,STATUS.md,TASKS.md,DECISIONS.md}`.
Forbidden: everything else; no new dependencies, schema, source-event, recorder or diagnostic behavior changes, or edits to Xcode project files.
Steps: Query projected trip evidence by insertion order; derive gap-safe route/distance/reliability; add typed native MapKit view contract and embedding; implement home, history and detail with debug navigation; test and validate once, review diff, commit and push branch only.
Tests required: ordering/filtering, accepted/rejected handling, segment/reset/gap separation and distance, measured/partial/unknown, zero evidence, live projected-only refresh, history/detail, Dart Pigeon mapping, existing regression suite; `dart format .`, `flutter analyze`, `flutter test`.
Acceptance criteria: Native blue route and fit/default camera; projected evidence only; no bridged gaps or fabricated distance; all three screens usable and debug/export reachable; generated bindings committed; Windows validation green, native compile/device deferred to owner.
Reviewer: Owner

### T-019 — Durable diagnostics and local export
Owner: Claude Code CLI
Status: review
Branch: task/T-019-diagnostics-export
Plan refs: D-035, §5.2–§5.4, §6.4
Goal: Add v3 diagnostic persistence for defined failures and user-initiated JSON export to iOS Files Documents via Pigeon.
Allowed files: `lib/data/database/{tables.dart,app_database.dart,app_database.g.dart}`, `lib/data/events/event_repository.dart`, `lib/data/projection/projection_state_repository.dart`, `lib/data/diagnostics/{diagnostic_entry.dart,diagnostic_repository.dart,diagnostic_bundle_exporter.dart}`, `lib/app/{raw_event_writer.dart,recorder_runtime.dart,recorder_event_ingestion.dart,recorder_session.dart,projection_drain_coordinator.dart,diagnostics_coordinator.dart}`, `lib/debug/recorder_debug_screen.dart`, `lib/main.dart`, `pigeons/recorder.dart`, `lib/bridge/generated/recorder.g.dart`, `ios/Runner/Generated/Recorder.g.swift`, `ios/Runner/Recorder/RideRecorder.swift`, `ios/Runner/Info.plist`, `test/data/database/app_database_test.dart`, `test/data/diagnostics/{diagnostic_repository_test.dart,diagnostic_bundle_exporter_test.dart}`, `test/app/{raw_event_writer_test.dart,recorder_session_test.dart,recorder_event_ingestion_test.dart,projection_drain_coordinator_test.dart,diagnostics_coordinator_test.dart,recorder_test_fakes.dart}`, `test/widget_test.dart`, `docs/{CODEMAP.md,STATUS.md,TASKS.md,DECISIONS.md}`
Forbidden: everything else; no new dependencies, remote behavior, or unrelated bridge changes.
Steps: Migrate v2 to v3; wire narrow unawaited best-effort diagnostics; generate Pigeon bindings for Documents path and implement Swift host; add size-checked local bundle and warning/debug action.
Tests required: migration/evidence, JSON validation and pruning isolation, raw/native/projection sources, nonblocking failure swallowing, exact payload and ID ordering, oversize no file, UI warning/outcome, Dart Pigeon path boundary; `dart format .`, `flutter analyze`, `flutter test`.
Acceptance criteria: D-035 fields, retention, capture and export constraints; generated Dart/Swift bindings committed; only approved files changed; Windows validation green; iOS/device verification explicitly deferred to owner.
Reviewer: Owner

### T-018 — Automatic projection processing and startup drain
Owner: Claude Code CLI
Status: done
Branch: task/T-018-projection-runner
Plan refs: §3.2, §5.2–§5.4, §15 M2; D-034
Goal: Automatically and serially project persisted raw events, drain pending events at startup, and expose blockage/retry in the debug console.
Allowed files: `lib/main.dart`, `lib/app/**`, `lib/debug/**`, `lib/data/events/**`, `lib/data/projection/**`, `test/app/**`, `test/debug/**`, `test/data/events/**`, `test/data/projection/**`, `test/widget_test.dart`, `docs/DECISIONS.md`, `docs/TASKS.md`, `docs/STATUS.md`, `docs/CODEMAP.md`
Forbidden: everything else.
Steps: Add single-flight drain coordinator and runtime visibility; wire shared raw writer and startup; show event status and explicit debug retry; add Windows tests.
Tests required: write isolation, native continuation, ordering, startup/restart, failure stop/block/reporting/retry, single flight, debug UI; `dart format .`, `flutter analyze`, `flutter test`.
Acceptance criteria: D-034 behavior with D-033 atomicity/idempotence unchanged; validation green.
Reviewer: Owner

### T-017 — Event projections and restart-safe processing
Owner: Claude Code CLI
Status: done
Branch: task/T-017-event-projections
Plan refs: §3.2, §5.2–§5.4, §6.2, §7.2, §15 M2; D-033
Goal: Migrate persistence to v2 and atomically project raw events into restart-safe trip, segment, and GPS evidence.
Allowed files: `lib/main.dart`, `lib/app/**`, `lib/debug/**`, `lib/data/database/**`, `lib/data/events/**`, `lib/data/projection/**`, `test/app/**`, `test/data/**`, `test/debug/**`, `test/widget_test.dart`, `docs/DECISIONS.md`, `docs/TASKS.md`, `docs/STATUS.md`, `docs/CODEMAP.md`
Forbidden: everything else, including domain, bridge, iOS/Pigeon, dependencies, maps, motion, HealthKit, and Riverpod.
Steps: Add the v1-to-v2 migration, shared raw-event writer, explicit snapshot codec and atomic projection processor, with focused Windows tests.
Tests required: migration, snapshot, atomic rollback/order/restart/idempotence, manual confirmation safeguards, GPS projection, shared writer, and runtime persistence-failure coverage; `dart format .`, `flutter analyze`, `flutter test`.
Acceptance criteria: D-033 behavior, stable insertion-ID processing, no fabricated distance/native data, and all validation green.
Reviewer: Owner

### T-016 — Raw recorder event ingestion and debug console
Owner: Claude Code CLI
Status: done
Branch: task/T-016-recorder-event-ingestion
Plan refs: §3.1, §3.2, §4, §5.2, §15 M2; D-032
Goal: Persist every live recorder callback as raw evidence and expose manual recorder controls and recent events in a minimal debug console.
Allowed files: `lib/main.dart`, `lib/app/**`, `lib/debug/**`, `lib/data/events/**`, `test/app/**`, `test/debug/**`, `test/data/events/**`, `test/widget_test.dart`, `docs/DECISIONS.md`, `docs/TASKS.md`, `docs/STATUS.md`, `docs/CODEMAP.md`
Forbidden: everything else; especially bridge/native contracts, schema, domain, and dependencies.
Steps: Implement serial callback ingestion and observable errors; manual session start/stop with D-032 write ordering; add `readRecent(limit)` and debug UI; update docs.
Tests required: repository recent ordering/limit/integrity; callback mapping, timestamps, ordering and write failures; manual start/stop persistence and native failures; widget status/errors/events; `dart format .`, `flutter analyze`, `flutter test`.
Acceptance criteria: D-032 mapping and failure behavior; Pigeon callbacks installed before manual controls; explicit disposal; no additional repositories or trip processing; all validation green.
Reviewer: Owner

### T-015 — Drift local data foundation
Owner: Claude Code CLI
Status: done
Branch: task/T-015-drift-data-foundation
Plan refs: §4, §5.2–§5.4, §15 M2; D-031
Goal: Establish the version-1 Drift schema, production opener, and append-only event repository without live ingestion.
Allowed files: `lib/data/**`, `test/data/**`, `pubspec.yaml`, `pubspec.lock`, `docs/DECISIONS.md`, `docs/TASKS.md`, `docs/STATUS.md`, `docs/CODEMAP.md`
Forbidden: everything else.
Steps: Add only required Drift dependencies; implement seven tables and planned indexes; add injectable test database and event repository; commit generated code; update docs.
Tests required: schema tables/indexes, event field and JSON integrity, insertion order, selective processing, immutable fields, and reopen persistence; `dart format .`, `flutter analyze`, `flutter test`.
Acceptance criteria: schemaVersion 1; exactly D-031 tables and §5.3 indexes; raw events append-only except processed false-to-true; Windows tests pass; no runtime bridge/UI integration.
Reviewer: Owner

### T-001 — Agent dry-run (Antigravity)
Owner: Antigravity
Status: done
Branch: none (read-only)
Goal: Prove the agent loads AGENTS.md and the docs correctly.
Allowed files: none (read-only task)
Steps: Read AGENTS.md, docs/STATUS.md, docs/TASKS.md, docs/DECISIONS.md.
Acceptance criteria: Reply with (1) the 5 most important hard rules, (2) D-007, D-009, D-010 in your own words, (3) the test commands, (4) what you can't do on Windows. No file edits.

### T-002 — Agent dry-run (Codex)
Owner: Codex
Status: done
Same as T-001.

### T-003 — Domain skeleton + haversine
Owner: Antigravity
Status: review
Branch: task/T-003-domain-geo
Plan refs: §5.1, §7.1
Goal: Create pure-Dart enums and a haversine function with tests.
Allowed files: lib/domain/**, test/domain/**
Tests required: haversine known values (0.001° latitude ≈ 111.2 m ± 0.5 m; same point = 0; antimeridian case).
Acceptance criteria: `flutter test` green; no Flutter imports in lib/domain.
Reviewer: Codex (T-004)

### T-004 — Review T-003
Owner: Codex
Status: done
Branch: review only (comments), fixes only if owner approves
Goal: Review diff of T-003 against AGENTS.md + D-003; run tests; report.
Allowed files: none unless approved

### T-005 — GpsFilter §7.2
Owner: Antigravity
Status: done
Branch: task/T-005-gps-filter
Plan refs: §7.2, §6.4
Goal: Implement pure-Dart GPS filter with two-reference design (C3/D-010); full unit tests.
Allowed files: lib/domain/**, test/domain/**
Tests required: one per RejectReason + 5 golden scenarios + 1 property test + T-006R tests A-I.
Acceptance criteria: dart format clean, flutter analyze no issues, flutter test passes (32 tests).
Notes: T-005R2 applies D-020 split-baseline (lastRawTsMs + lastTrusted + anchorClearedConservatively). 32 tests green.
Reviewer: Owner (merged to main)

### T-007 — Code tree refactor
Owner: Antigravity
Status: done
Branch: task/T-007-code-tree
Goal: Pure move refactor into feature tree (geo/, gps/, activity/, trip/, shared/), CODEMAP, and code rules.
Allowed files: lib/**, test/**, docs/**, AGENTS.md, .agents/**
Tests required: full suite passes with identical assertions (51 tests, 110 expect calls).
Acceptance criteria: dart format clean, flutter analyze no issues, flutter test passes (51 tests), CODEMAP.md created, no file > 250 lines except gps_filter.dart.
Reviewer: Owner (merged to main)

### T-008 — ActivityClassifier §7.6
Owner: Antigravity
Status: done
Branch: task/T-008-activity-classifier
Plan refs: §7.6, D-022, D-023
Goal: Pure function activity classification over pre-aggregated ActivityWindow with trapezoid memberships and test suite.
Allowed files: lib/domain/activity/**, lib/domain/domain.dart, test/domain/activity/**, docs/**
Tests required: 9 membership tests + 9 classifier scenario/property tests.
Acceptance criteria: dart format clean, flutter analyze no issues, flutter test passes (82 tests).
Reviewer: Owner (merged to main)

### T-009 — ActivityStateMachine & DomainConfig
Owner: Antigravity
Status: done
Branch: task/T-009-activity-state (merged to main)
Plan refs: §6.1, §6.4, D-024, D-025
Goal: Pure-Dart ActivityStateMachine debouncing with candidate hysteresis and maxEvidenceGapMs; DomainConfig aggregating all 4 domain configs.
Allowed files: lib/domain/activity/**, lib/domain/config/**, lib/domain/domain.dart, test/domain/activity/**, test/domain/config/**, docs/**
Tests required: 11 ActivityStateMachine scenario tests, 1 config assert test, 2 DomainConfig/TripConfig tests.
Acceptance criteria: dart format clean, flutter analyze no issues, flutter test passes (97 tests).
Reviewer: Owner / Codex

### T-010 — TripStateMachine phase 1 §6.2
Owner: Antigravity
Status: done
Branch: task/T-010-trip-state-machine (merged to main)
Plan refs: §6.2, D-026, D-027
Goal: Pure-Dart TripStateMachine step(TripState, TripEvent, TripConfig) -> TripStepResult with sealed events and commands; 22 scenario/property tests.
Allowed files: lib/domain/trip/**, lib/domain/domain.dart, test/domain/trip/scenarios/**, docs/**
Tests required: 22 tests (idle/pending 1-8, active/paused 9-17+20, property 18-19+21-22).
Acceptance criteria: dart format clean, flutter analyze no issues, flutter test passes (124 tests).
Reviewer: Owner (merged to main)

### T-011 — TripStateMachine phase 2 (M4)
Owner: Claude Code
Status: done
Branch: task/T-011-trip-state-phase2
Plan refs: §6.2, §6.4, §7.2, §7.5, §7.7, D-026, D-027, D-030
Goal: Implement D-030 pure-Dart phase-2 trip lifecycle behavior: safe GPS-gap/recovery closure, idle cycling auto-start, forgotten-trip review closure, and close reasons.
Allowed files:
- lib/domain/trip/**
- lib/domain/config/trip_config.dart
- lib/domain/domain.dart
- test/domain/trip/**
- test/domain/config/**
- docs/DECISIONS.md
- docs/TASKS.md
- docs/STATUS.md
- docs/CODEMAP.md
Forbidden: everything else.
Steps: Extend the trip event/command/state/status contracts and transitions only as D-030 requires; preserve phase-1 behavior except where D-030 supersedes it; update public exports and CODEMAP for every added, moved, or deleted file.
Tests required: cycling-only idle auto-start at historical activity time; duplicate/stale auto-start safety; safe gap timestamp clamping plus anchor reset and no bridged segment; paused-to-forgotten/resume and conservative auto-close; recovery timestamp distinction, terminal no-open-segment safety, and duplicate/stale safety; user-stop close reason; monotonic timestamp and no-duplicate-terminal-command properties.
Acceptance criteria: pure Dart with no dependencies or GPS implementation changes; all derived timestamps clamped and monotonic; gaps use SegmentType.gap; auto-close and recovery end as needsReview with the required close reason and terminal commands; dart format clean, flutter analyze no new issues, flutter test passes.
Reviewer: Owner

---

### T-013 — Native iOS recorder migration & Pigeon live bridge
Owner: Claude Code CLI
Status: done
Branch: `task/T-013-native-recorder`
Plan refs: §3.1, §3.2, §4, D-015, D-029
Goal: Migrate the required Core Location recorder behavior and expose a typed, live raw-GPS bridge to Dart with no native threshold filtering.
Allowed files: `pigeons/recorder.dart`, `lib/bridge/**`, `ios/Runner/AppDelegate.swift`, `ios/Runner/SceneDelegate.swift`, `ios/Runner/Info.plist`, `ios/Runner/Recorder/**`, `ios/Runner/Generated/**`, `ios/Runner.xcodeproj/project.pbxproj`, `test/bridge/**`, `docs/DECISIONS.md`, `docs/TASKS.md`, `docs/STATUS.md`, `docs/CODEMAP.md`, `pubspec.yaml`, `pubspec.lock`
Note: `ios/Runner.xcodeproj/project.pbxproj` is limited to registering `RideRecorder.swift` and `Recorder.g.swift` as Runner target sources.
Forbidden: all other files, especially `lib/domain/**`, `probes/**`, persistence/data, UI, HealthKit, NFC, and buffering/replay features.
Steps: Add Pigeon contract and generated bindings; migrate live raw Core Location recorder; add Dart adapter and unit tests.
Tests required: bridge command dispatch, raw-fix mapping, required fields, native error and authorization mappings; `dart format .`, `flutter analyze`, `flutter test`.
Acceptance criteria: typed Pigeon live bridge with raw location forwarding; generated Dart/Swift bindings committed; domain unchanged; required bridge tests pass.
Reviewer: Owner / Codex

---

### T-014 — Windows domain replay harness
Owner: Claude Code CLI
Status: done
Notes: Must not run in parallel with T-013 because both update shared documentation.
Branch: `task/T-014-windows-replay-harness`
Plan refs: §13.2, §13.3

Goal: Add a test-only Windows replay harness under `test/replay/` that reads CSV fixtures from `test/fixtures/` and exercises existing public pure-Dart domain APIs. Use real-trip CSV replays for regression coverage and the §13.3 synthetic CSV golden scenarios.

Allowed files: `test/replay/**`, `test/fixtures/**`, `test/helpers/**` (only if a shared replay helper is necessary), `docs/TASKS.md`, `docs/STATUS.md`, `docs/CODEMAP.md`

Forbidden scope: `lib/domain/**`, `ios/**`, `lib/bridge/**`, persistence, production pipeline/coordinator code, Pigeon/bridge design, dependencies, and all files outside Allowed files. Do not add JSONL fixtures.

Steps:
1. Define a CSV fixture format within the test harness sufficient to replay supported existing public domain inputs, with parsing contained entirely under `test/replay/`.
2. Add CSV fixtures named by §13.3: `stationary_drift_30min.csv`, `traffic_light_stops.csv`, `bike_then_walk.csv`, `bike_then_microbus.csv`, and `gps_tunnel_gap.csv`.
3. Implement replay tests that feed fixture rows only through existing public pure-Dart domain APIs and assert observable golden outcomes.
4. Add at least one real-trip CSV replay fixture pattern so every future field bug can be captured as a regression fixture.
5. If a required golden assertion cannot be expressed through an existing public API, stop and report the exact missing public API as a blocker; do not design or add production APIs.
6. Update `docs/CODEMAP.md`, `docs/STATUS.md`, and this task’s status when the work is complete.

Tests required:
- Replay every §13.3 CSV fixture on Windows through existing public pure-Dart domain APIs.
- Assert `stationary_drift_30min.csv` produces zero distance.
- Assert the remaining fixture outcomes only where existing public APIs expose enough observable state or commands to make the golden assertion.
- Run `dart format .`, `flutter analyze`, and `flutter test` once at the end.

Acceptance criteria:
- All replay harness code is test-only under `test/replay/`; all fixtures are CSV under `test/fixtures/`.
- No production, bridge, iOS, persistence, or coordinator code changes.
- No new dependencies.
- The harness exercises public pure-Dart domain APIs only.
- Every §13.3 synthetic scenario has a CSV fixture and replay test.
- Any unsupported golden assertion is reported as an exact missing public API blocker, without production-code design or changes.
- `docs/CODEMAP.md` and `docs/STATUS.md` are updated.
- Formatting, analysis, and test results are reported exactly as run; no result is claimed without execution.

Reviewer: Antigravity

Codemagic requirement: Not required for this isolated Windows-only test task because it changes neither Swift nor iOS build inputs; the owner should run the unsigned Codemagic build at the end of the relevant larger M2 phase.

Open questions:
- Which required outcomes for `traffic_light_stops.csv`, `bike_then_walk.csv`, `bike_then_microbus.csv`, and `gps_tunnel_gap.csv` are observable through the current public domain APIs without inspecting or extending production code?
- If any is not observable, what exact existing public API is missing for that assertion?

