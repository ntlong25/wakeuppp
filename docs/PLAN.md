# WakeMission – Revised Plan

Supersedes `wakemission_implementation_plan.md`. Behaviour is defined in `docs/SPEC.md`.

## Direction (v2)
Instead of owning alarms, WakeMission rides on Apple's Clock alarms: a Shortcuts automation ("alarm is stopped") starts the wake-up flow, and a chain of system-owned AlarmKit alarms rings again until the missions are done. The app is only settings + missions.

## Status
| Area | Status |
|---|---|
| Docs (CLAUDE.md, SPEC, PLAN) | done |
| Settings store, RingingStore, AlarmService chain, intents, Shortcuts provider | done, **uncompiled** |
| Typing / Math / Photo missions, reference registration | done, **uncompiled** |
| Native-style Home, Missions, Connect-to-Clock guide, Onboarding | done, **uncompiled** |
| Unit tests (math, typing, photo decider, store, settings) | done, **unrun** |
| Verify Shortcuts "Alarm is stopped → Run Immediately" while locked on iOS 26/27 | TODO (device) |
| Verify 2 s / 5 s AlarmKit fixed alarms are accepted | TODO (device) |
| Calibrate FeaturePrint thresholds | TODO |
| App icon | TODO |

## Next
1. Device-test matrix in SPEC §6, tune ring delays.
2. Decide on a "quiet while working" option if the repeated alerts during missions are too noisy.
3. TestFlight, store assets, privacy policy, review notes (explain AlarmKit, Shortcuts setup, camera).
