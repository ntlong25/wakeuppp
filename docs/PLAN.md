# WakeMission – Revised Plan

Supersedes `wakemission_implementation_plan.md`. See `docs/SPEC.md` for behavior.

## Corrections to the original plan
1. Target is **iOS 26 / Xcode 26** (AlarmKit), not iOS 18/Xcode 16.
2. AlarmKit stop/secondary buttons dismiss the alarm; continuing to ring requires in-app audio + backup **nag alarms**.
3. Snooze removed (contradicts product).
4. Photo mission uses FeaturePrint reference matching with classification fallback and a guaranteed escape (math).
5. Intents hand off via persisted `RingingStore`, not in-memory notifications.

## Status
| Area | Status |
|---|---|
| Docs (CLAUDE.md, SPEC, PLAN) | done |
| Models, schedule math, ringing store, streaks (+tests) | done, **uncompiled** |
| AlarmService (weekly/fixed, nags), intents | done, **uncompiled** |
| Typing / Math / Photo missions, registration | done, **uncompiled** |
| Onboarding, stats, editor drafts | done, **uncompiled** |
| Compile + unit tests on macOS | TODO (first thing on a Mac) |
| Physical-device matrix (SPEC §7) | TODO |
| FeaturePrint threshold calibration | TODO |
| App icon / asset catalog | TODO |

## Remaining roadmap
- **Week A (Mac)**: `xcodegen generate`, fix compile errors, run unit tests, run Milestone 0 on device (matrix 1–8).
- **Week B**: calibrate photo thresholds in low light; tune nag count/interval; accessibility (Dynamic Type, VoiceOver on keypad).
- **Week C**: TestFlight with 5–10 testers; edge cases (low power, calls, DST, midnight).
- **Week D**: icon, screenshots, privacy policy, review notes (explain AlarmKit + camera usage, demo "Test alarm"), submit.
