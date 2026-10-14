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
- Never weaken, delete, or change expected values of a required test to make it pass. If a required test seems wrong, stop and report it as an open question.
- Run format/analyze/test ONCE at the end (re-run only after a fix).
- If you must stop before finishing (limit/error/timeout): commit work on the task branch as "WIP: <TASK-ID> <what is done>" and write done/remaining/next in docs/STATUS.md.
- Never write a rating row for yourself in AGENT_LOG; rows are provided in the prompt.

## Code organization
- Organize by feature (geo/, gps/, activity/, trip/), not by type.
- One reason to change per file. Split when parts change independently; keep together what always changes together. Size is a signal, not a rule: a file over ~250 lines or a function over ~40 lines must justify itself or be split.
- test/ mirrors lib/. Scenario tests go in test/<feature>/scenarios/. Shared helpers live in test/helpers/ — never duplicated.
- docs/CODEMAP.md: one line per file. Update it in the same commit when adding, moving, renaming, or deleting a file.
- Navigation: read CODEMAP.md first, then open only the target files.
- Review prompts end on the reviewed branch, never on main.
- No dead code, no commented-out code. Comments explain WHY, not WHAT.
- Git actions only when the prompt says so: commit, push, and merge happen ONLY as written in the task prompt. Never commit on your own initiative; if you think an extra commit is needed, stop and ask the owner. Exception: a WIP commit when hitting a limit.
- Merge to main ONLY when the prompt contains "OWNER-APPROVED MERGE: <branch>". Then squash-merge that branch only; the full test suite must pass before push, otherwise reset to origin/main and stop.

## Owner vs agent responsibilities
Agents do: code, tests, docs/STATUS.md and docs/TASKS.md updates, commits on task branches, pushing task branches, opening the final report.
Owner only: merging to main, approving decisions, anything involving accounts/payments/signing, running the app on the iPhone.
Agents must list any step they could not do under "Owner actions needed" in the report.

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
Agent tool: <Antigravity | Codex>
Model (self-reported): <name/version>
```

## Token discipline
- Don't re-explain the architecture or summarize unchanged files.
- Don't paste whole files in reports; reference paths and line ranges.
- Ask one precise question instead of exploring broadly.
