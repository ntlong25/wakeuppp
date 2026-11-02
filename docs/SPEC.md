# WakeMission – Technical Spec (v2)

Product rule: **an alarm only stops for good once the missions are done; until then it keeps coming back.** No snooze.

Platform: iOS 26+, Swift 6 (strict concurrency), SwiftUI, AlarmKit, App Intents, Vision, AVFoundation. No SwiftData (state is small UserDefaults blobs).

## 1. Concept
- Alarms are created in the app (Clock-style list and editor) and scheduled with AlarmKit. No setup beyond granting permission.
- Decision history: a Clock + Shortcuts design was tried and dropped. iOS has no API to read Clock alarms or create automations, so it depended on every user completing a manual five-step setup.
- All alarms use `sound: .default`, so the first alarm and every follow-up sound identical. Per-alarm sound choice is not offered, because the app cannot use Apple's tone list.
- One global mission sequence applies to all alarms.

## 2. State and data
### AlarmEntry (UserDefaults, JSON array, key `com.wakemission.alarms`)
`id` (also the AlarmKit id), `hour`, `minute`, `label`, `repeatDays` (1 = Sunday … 7 = Saturday, empty = one-shot), `isEnabled`, `oneShotFireDate`.

### WakeSettings (UserDefaults, JSON, key `com.wakemission.settings`)
| field | notes |
|---|---|
| missions | ordered `[MissionDraft]` (type, difficulty, optional `PhotoMissionConfig` JSON) – one global sequence |
| ringMode | `RingMode`: every 5 s (default) / 10 s / 30 s / 60 s / continuous (re-arm after 2 s) |

`PhotoMissionConfig { featurePrint: Data, thumbnail: Data }` – `featurePrint` is a secure-coded `VNFeaturePrintObservation`.

### RingingSession (UserDefaults, key `com.wakemission.ringingSession`)
`startedAt`, `pendingAlarmIds`. Sessions older than 60 min are discarded and never re-armed (runaway protection).

## 3. Lifecycle
```
User alarm fires (system alert, default tone)
     user taps Start Mission / Wake Up ─▶ OpenAppFromAlarmIntent(isFollowUp: false)
         WakeFlow.start(): begin session, arm follow-up after ringMode.rearmDelay
     app opens ─▶ AppState.consumePending() ─▶ missions full-screen
Follow-up alarm fires ─▶ user dismisses ─▶ OpenAppFromAlarmIntent(isFollowUp: true)
         WakeFlow.rearm(): arm the next follow-up, only if the session still exists
all missions done ─▶ AppState.completeWakeUp(): cancelAll(); RingingStore.clear()
```
Rules:
1. **AlarmKit buttons dismiss the alarm they belong to.** Ringing continues only because the next follow-up is armed at that moment. At most one follow-up is pending.
2. **Closing the app cannot be prevented by iOS.** The pending follow-up is system-owned, so it fires even if the app is killed.
3. In "every N seconds" mode the alarm also rings while the user is doing missions. "Continuous" shortens the gap to 2 s.
4. Cold launch safe: hand-off goes through `RingingStore`, never in-memory.
5. Scheduling: one-shot → `.fixed(nextFireDate)`; repeating → `.relative(.weekly(days))`, computed by `AlarmScheduleMath`.
6. Completion cancels follow-ups only. Repeating user alarms stay scheduled.
7. One-shot alarms switch off automatically once `oneShotFireDate` has passed (checked when the app becomes active).
8. Min delay for `.fixed` alarms in AlarmKit is untested – verify 2 s / 5 s on device.

## 4. Missions
All missions call `onCompleted` **exactly once**; `MissionCoordinator` also ignores completions for a non-current step.

### Typing
Phrase pool by difficulty and app language (English or Vietnamese). `TypingValidator`: case- and accent-insensitive (đ counts as d), smart punctuation normalised, whitespace collapsed. Live feedback (green prefix, red border on mismatch). A change adding more than 1 character at once (paste) is rejected. Completes automatically.

### Math
Easy `a±b`; Medium add/sub/`a×b`; Hard `(a×b)−c` with `c < a×b`. Answers are non-negative. Required problems: 2 / 3 / 4.

### Photo
- Live camera only. 640×480 BGRA at ≤ 5 fps.
- Reference match when registered (`VNGenerateImageFeaturePrintRequest`, distance < 0.55 / 0.45 / 0.35 by difficulty; **calibrate on device**); otherwise `VNClassifyImageRequest` (sink/washbasin/basin/faucet/bathroom/toilet ≥ 0.70).
- `PhotoMatchDecider`: 4 consecutive matches and a live feed (luma range ≥ 0.004 over 10 frames).
- Never stuck: camera denied → math immediately; "Can't scan? Solve math instead" after 90 s.

### Empty configuration
If no missions are configured a single easy math mission is used.

## 5. UI (Apple-native look)
System colours, fonts, grouped `List`, large title, light/dark follows the system, `AccentColor` burnt orange. Tokens, states and rationale: `docs/DESIGN.md`.
- **Alarms tab**: Edit, +, big time rows with label and repeat, toggle, swipe to delete, tap to edit, empty state, warning if alarms are denied.
- **Add/Edit Alarm**: wheel picker, Repeat (weekday list), Label, Delete. No Sound or Snooze row.
- **Settings tab**: Missions, Ring Again, Test Wake-Up Flow.
- **Missions**: add/delete/reorder (Edit), difficulty menu, photo reference registration.
- **Onboarding** (first launch): promise, how it works, permissions (AlarmKit required, Camera optional).
- **Wake-up flow**: full-screen cover with progress bar and the current mission.

Languages: English (source) and Vietnamese (`Resources/vi.lproj`), following the iPhone's language.

## 6. Manual test matrix (physical iPhone)
| # | Scenario | Expected |
|---|---|---|
| 1 | One-shot alarm, phone locked | rings at the set minute with the default tone |
| 2 | Tap Start Mission, then lock the phone | alarm rings again after the ring delay |
| 3 | Tap Start Mission, then kill the app | alarm rings again after the ring delay |
| 4 | Finish all missions | no further alarm; session cleared |
| 5 | Repeating alarm completed | still on, fires on the next selected day |
| 6 | One-shot completed | toggle shows off after returning to the app |
| 7 | Silent switch / Focus | alarm still sounds |
| 8 | Delete an alarm / toggle off | does not fire |
| 9 | Typing: paste whole phrase | rejected |
| 10 | Photo: camera denied | falls back to math |
| 11 | Ring mode Continuous / 60 s | gap matches the setting |
| 12 | Ignore follow-ups for 60 min | chain stops (session expires) |
| 13 | Alarms permission denied, then save | "Couldn't Set Alarm" alert, alarm stays off |

## 7. Known risks
- AlarmKit may rate-limit or reject alarms scheduled only a few seconds ahead.
- A one-shot alarm stores an absolute date, so a time zone change before it fires keeps the original moment.

## 8. Out of scope
Clock app integration, per-alarm missions or sounds, snooze, stats, widgets, Apple Watch.
