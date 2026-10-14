# DECISIONS — BikeTrack

Settled decisions. Agents must not reopen these. To change one: add a new entry with status "Proposed" and wait for the owner.
Rule: never edit an old decision's text. Add a new decision and set the old one's Status to "Accepted — amended by D-XXX" or "Superseded by D-XXX".

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
| D-017 | GeoPoint: immutable value type (latDeg, lonDeg) in lib/domain, no behavior except equality | Needed by GpsFilter (§7.2); approved after T-004 | Accepted |
| D-018 | GpsSample (tsMs, GeoPoint, hAccuracyM) + FilterState (lastReceived, anchor, prevSpeedMps) + GpsFilterConfig in lib/domain; filter is a pure function | Needed for §7.2 | Accepted — amended by D-020, D-021 |
| D-019 | Conservative anchor policy: clear anchor on impossibleSpeed, spike, and isStationary=true (confirmed stationary). prevSpeedMps = instantaneous speed lastReceived->current, always. Non-finite inputs are invalid. Undercount is preferred over phantom distance. | T-006R blocker + majors | Accepted — amended by D-020 |
| D-020 | Amends D-019: split baseline. lastRawTsMs (ordering + gap) is updated by every point passing checks 1–4. lastTrusted (point) + prevSpeedMps are updated ONLY by points NOT rejected at checks 6–7. prevSpeedMps = instantaneous lastTrusted->current on every non-rejected path, including stationary. Anchor clearing from D-019 is unchanged. | Spike cascade after one outlier lost ~20 m | Accepted |
| D-021 | Consecutive-outlier anchor guard: when impossibleSpeed or spike clears the anchor, set anchorClearedConservatively=true. Until a successful anchor reset, explicit resetAnchor, stationary path, or gap reset clears it, a non-gap anchor-reset candidate must pass speed and acceleration checks against lastTrusted with prevSpeedMps unchanged; rejected candidates update only lastRawTsMs; a successful reset adds 0 m. | Prevents consecutive outliers from becoming anchors while keeping conservative undercount | Accepted |
| D-022 | ActivityClassifier is a pure function over a pre-aggregated ActivityWindow (cmTypes, cmConfidence?, cadenceSps?, speedMps? = median GPS speed of the window, stopPatternScore? in [0,1]). A missing input makes its term contribute 0 to every type (no bias). Speed memberships are trapezoids defined in config. Output = type + all four scores. NFC is never an input. Hysteresis is a separate component (later task). | Section 7.6, testable on Windows | Accepted |
| D-023 | Invalid ActivityClassifier inputs: non-finite or negative speedMps/cadenceSps, and non-finite or out-of-range stopPatternScore, are treated as missing (term = 0). CM evidence counts only when cmTypes, after removing nothing, is exactly one of {cycling},{walking},{automotive},{stationary}, or exactly {automotive, stationary} (treated as automotive: car stopped at a light). Any other set (several types, running, unknown) gives CM term 0. ActivityClassifierConfig is validated by asserts: all weights and conf values >= 0; conf values <= 1; w1+w2+w3 <= 1; w1+w2+w5 <= 1; minBestScore and minMargin in [0,1]; cadenceFull > 0; each trapezoid a <= b <= c <= d. All scores are finite and in [0,1]. | T-008R: NaN propagation, unbounded config, ambiguous CM flags | Accepted |
| D-024 | ActivityStateMachine (§6.1) is a pure step(state, classifiedType, nowMs, cfg). The current type changes only after a candidate type persists for its hysteresis: cycling 30 s, walking 20 s, automotive 60 s, stationary 45 s, unknown 30 s, running 30 s. On switch, sinceMs = candidateSinceMs. Input equal to the current type clears the candidate. Input with nowMs <= lastUpdateMs is ignored (state unchanged). If nowMs - lastUpdateMs > maxEvidenceGapMs (120 s), the candidate restarts at nowMs. Initial type is unknown. A confidence field is deferred. | Prevent flicker; keep the real start time of a change | Accepted |
| D-025 | DomainConfig aggregates GpsFilterConfig, ActivityClassifierConfig, ActivityStateConfig and TripConfig. TripConfig holds §6.4 values: pendingMs 5 min, pauseMs 3 min, forgotMs 15 min, autoCloseMs 45 min, modeChangeMs 60 s, gapMs 30 s, pauseRegionRadiusM 100, cadenceWalkingMinSps 1.2. TripConfig.gapMs must equal GpsFilterConfig.gapMs (assert). | Single source for thresholds (D-014) | Accepted |
| D-026 | TripStateMachine phase 1: pure step(TripState, TripEvent, TripConfig) -> TripStepResult(state, commands). Statuses: pending, active, paused, completed; idle (no open trip) is TripState.status == null, TripStatus is not extended. Events: userStart, nfcScan, userStop, activity, tick. Events with nowMs < lastEventMs ignored. Deferred to phase 2 (M4): suspectedForgotten, autoClosed, needsReview, auto-detect start, GPS gap segments, reconcile. Pause does not close the segment. User stop while paused ends at pausedSinceMs. Start events with an open trip emit AskOpenTripDecision only. | §6.2 split; phase 1 needed for M2 | Accepted |


