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
Status: review
Branch: task/T-005-gps-filter
Plan refs: §7.2, §6.4
Goal: Implement pure-Dart GPS filter with two-reference design (C3/D-010); full unit tests.
Allowed files: lib/domain/**, test/domain/**
Tests required: one per RejectReason + 5 golden scenarios + 1 property test.
Acceptance criteria: dart format clean, flutter analyze no issues, flutter test passes.
Reviewer: Codex
