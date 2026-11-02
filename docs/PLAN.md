# WakeMission – Revised Plan

Supersedes `wakemission_implementation_plan.md`. Behaviour is defined in `docs/SPEC.md`.

## Direction (v3)
WakeMission owns its alarms again, in a Clock-style UI, so it works with no setup. The Clock + Shortcuts design was dropped because iOS offers no way to create the automation for the user. Follow-up alarms ring until the missions are done.

## Status
| Area | Status |
|---|---|
| Docs (CLAUDE.md, SPEC, PLAN) | done |
| Alarm store, schedule math, AlarmService, follow-up chain, intent | done, **uncompiled** |
| Typing / Math / Photo missions, reference registration | done, **uncompiled** |
| Clock-style alarm list and editor, Settings tab, Onboarding | done, **uncompiled** |
| Vietnamese localization | done, **uncompiled** |
| Unit tests (math, typing, schedule, alarm entry, photo decider, store, settings) | done, **unrun** |
| Verify 2 s / 5 s AlarmKit fixed alarms are accepted | TODO (device) |
| Calibrate FeaturePrint thresholds | TODO |
| App icon | done (`Assets.xcassets/AppIcon`) |
| Design pass (critique + handoff) | done, **uncompiled**; see `docs/DESIGN.md` |

## Next
1. Device-test matrix in SPEC §6, tune ring delays.
2. Decide on a "quiet while working" option if the repeated alerts during missions are too noisy.
3. TestFlight, store assets, privacy policy, review notes (explain AlarmKit, Shortcuts setup, camera).
