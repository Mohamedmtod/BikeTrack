# ROADMAP — BikeTrack

Detail per milestone: `ENGINEERING_PLAN.md` §15. A milestone starts only after the previous gate passes.

| Milestone | Content | Gate |
|---|---|---|
| S0 | Workspace: Git, Flutter, agent files, first agent dry-run | Both agents summarize rules correctly without editing code |
| M0 | Feasibility app: build/sign/install on iPhone 14 Pro, Core Motion, Core Location (bg 15 min), NFC (Universal Link), HealthKit read | Each item marked pass / fail / needs paid account |
| M0.5 | Real project structure, packages, Config, CI choice | Builds + tests green |
| M1 | Pure domain on Windows: models, haversine, GpsFilter, classifier, TripStateMachine, fixtures | All tests green; stationary_drift = 0 m |
| M2 | Raw data logger + manual trip + NFC + debug/CSV | Raw data arrives and is stored completely |
| M3 | Core Motion + Core Location integration, background | 1-hour device test with measured gaps; no resume jump |
| M4 | Forgotten trip, auto-close, tail trim, reconcile, review UI | Phantom distance after forgotten hour ≈ 0 |
| M5 | HealthKit write/update/delete | No duplicates after 10 trips + 2 corrections |
| M6 | UI, stats, onboarding, battery tuning | — |
| M7 | 2 weeks calibration, set real targets | Targets defined from data |
