# Domain rules
- Pure Dart only: no `package:flutter`, no `dart:io`, no platform channels, no DateTime.now() inside logic (inject a clock/timestamps).
- State machines: `(State, Event) -> (State, List<Command>)`. Never execute side effects.
- Immutable models (freezed or const classes). Deterministic: same events => same result.
- Thresholds come from a `Config` object passed in.
- Distance: follow plan §7.2 exactly, including anchor reset (D-010) and stationary gate. Unknown distance = null, never 0 (D-011).
- Every branch of a transition table gets a unit test. Add property-style tests: "distance never increases while stationary".
