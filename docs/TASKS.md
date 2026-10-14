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
Status: review
Branch: task/T-010-trip-state-machine
Plan refs: §6.2, D-026
Goal: Pure-Dart TripStateMachine step(TripState, TripEvent, TripConfig) -> TripStepResult with sealed events and commands; 22 scenario/property tests.
Allowed files: lib/domain/trip/**, lib/domain/domain.dart, test/domain/trip/scenarios/**, docs/**
Tests required: 22 tests (idle/pending 1-8, active/paused 9-17+20, property 18-19+21-22).
Acceptance criteria: dart format clean, flutter analyze no issues, flutter test passes (119 tests).
Reviewer: Owner / Codex

### T-011 — TripStateMachine phase 2 (M4)
Owner: TBD
Status: todo
Branch: task/T-011-trip-state-phase2
Plan refs: §6.2, D-026
Goal: Implement deferred statuses: suspectedForgotten, autoClosed, needsReview; auto-detect start from idle; GPS gap segments; reconcile logic.
Allowed files: lib/domain/trip/**, test/domain/trip/**, docs/**
Tests required: TBD (full coverage of new statuses).
Acceptance criteria: dart format clean, flutter analyze no issues, flutter test passes.
Reviewer: TBD
