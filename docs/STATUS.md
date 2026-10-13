# STATUS — BikeTrack

Keep under 15 lines. Overwrite, don't append history.

- Current milestone: S0 (domain logic)
- Active task: none; T-005 branch ready for owner merge review
- Last completed: T-005R (conservative anchor policy, D-019, 46 tests pass)
- D-019 added: clear anchor on impossibleSpeed/spike/stationary; prevSpeed always instantaneous
- Next: owner merges T-003 + T-005 branches; then T-006 (TripStateMachine or ActivityClassifier)
- Blockers: none (T-003 still unmerged; T-005 depends on T-003)
- Open questions: macOS access path for M0 — owner to decide
- Repo: github.com/Mohamedmtod/BikeTrack | Toolchain: Flutter 3.47.7 / Dart 3.13.5