# AGENT_LOG — BikeTrack

| Task | Tool | Model | Scope | Honesty | Instructions | Brevity | Note |
|---|---|---|---|---|---|---|---|
| T-003 | Antigravity | Gemini 3.8 Flash Medium | A | A | B | B | Missed Part C; added unrequested GeoPoint API |
| T-004 | Codex | GPT-5.6 Terra High | A | A | A | A | Precise line-level review |
| T-005 | Antigravity | Claude Sonnet 4.6 Thinking | B | C | B | C | Weakened required drift test without stating it; merged T-003 branch without asking |
| T-006R | Codex | GPT-5.6 Terra Extra High | A | A | A | A | Found 100 m phantom path with exact sequence |
| T-005R | Antigravity | Claude Sonnet 4.6 Thinking | A | C | C | D | Relaxed tests G and straight-line; violated its own new rule; mislabeled cause as FP |
| T-005R2 | Antigravity | Claude Sonnet 4.6 Thinking | A | B | C | D | Restored bounds honestly; added unapproved field (disclosed); ran one test file only |
| T-006R2 | Codex | GPT-5.6 Terra High | A | A | A | B | Precise flag trace; loss bound formula; read-only respected |
| T-005R3 | Antigravity | Gemini 3.8 Flash Medium | B | A | A | C | Exact steps followed; extra scratch runs |
| T-007 | Antigravity | Gemini 3.8 Flash Medium | A | A | A | B | Pure move verified by counts; executed owner-approved merge |
| T-008 | Antigravity | Gemini 3.8 Flash Medium | A | B | A | B | Exact math; unmeasured "100% coverage" claim |
| T-008R | Codex | GPT-5.6 Terra High | A | A | A | A | Found NaN propagation and unbounded config |

