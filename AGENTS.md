# AGENTS.md — BikeTrack

Shared rules for every AI agent (Antigravity, Codex). Keep this file short. Details live in `docs/`.

## Project
iOS app (Flutter + Swift) that records bike trips and walking without phantom distance.
Owner and final decision maker: Mohamed (human). Agents execute; they do not make architecture decisions.

## Read before every task (only these)
1. `docs/STATUS.md` — current state.
2. `docs/TASKS.md` — your task, allowed files, acceptance criteria.
3. Only the docs/files the task references. Do NOT scan the whole repo.
`docs/ENGINEERING_PLAN.md` is the full reference; open only the section a task cites (e.g. "§7.2").

## Hard rules
- Work ONLY on the task assigned to you in `docs/TASKS.md`, ONLY in its "Allowed files".
- Never edit files another agent's active task owns.
- One task = one branch: `task/<TASK-ID>-<short-name>`. Never commit to `main` directly.
- Decisions in `docs/DECISIONS.md` are settled. To change one, STOP and propose a new decision entry; do not implement it.
- Changes to the data model, state machines, or the Dart<->Swift contract require an approved decision first.
- Do not guess iOS behavior (background, NFC, HealthKit, signing). If unsure, write it as an open question in your report.
- Never claim a test passed unless you ran it. State what you ran, what you could not run, and why.
- No new dependencies without listing them in your report with the reason.
- All thresholds go in the Config (see plan §6.4). No magic numbers in logic.
- Domain code in `lib/domain/` must be pure Dart: no Flutter imports, no platform channels, no I/O.

## Environment
- Dev machine: Windows. iOS build/sign/run is NOT possible locally.
- Runnable on Windows: `flutter analyze`, `flutter test`, `dart format`.
- Swift code under `ios/` can be written but not compiled here; mark it "uncompiled" in reports.

## Commands
- Format: `dart format .`
- Analyze: `flutter analyze`
- Test: `flutter test`

## Definition of done (every task)
1. `dart format .` clean, `flutter analyze` has no new issues, `flutter test` passes.
2. New logic has unit tests.
3. `docs/STATUS.md` updated (2–5 lines max).
4. Final report in this exact format:

```
## Report — <TASK-ID>
Summary: <1–3 lines>
Files changed: <list>
Commands run + results: <list>
Not run / why: <list>
Risks / open questions: <list>
Suggested next task: <1 line>
```

## Token discipline
- Don't re-explain the architecture or summarize unchanged files.
- Don't paste whole files in reports; reference paths and line ranges.
- Ask one precise question instead of exploring broadly.
