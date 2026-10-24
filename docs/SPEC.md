# WakeMission – Technical Spec (v2)

Product rule: **after a Clock alarm is stopped, the user must complete missions; until then, the system alarm keeps coming back.** No snooze, no in-app alarm creation.

Platform: iOS 26+, Swift 6 (strict concurrency), SwiftUI, AlarmKit, App Intents, Vision, AVFoundation. No SwiftData (state is two small UserDefaults blobs).

## 1. Concept
- Alarms are created and managed in Apple's **Clock** app (no public API exists to read or edit them from a third-party app).
- The user adds a one-time **Shortcuts automation**: *Alarm → Is Stopped (and optionally Is Snoozed) → Run Immediately → "Start Wake-up Missions" (WakeMission)*.
- When the Clock alarm is stopped, the automation runs `StartWakeMissionsIntent` in the background (no UI needed, works locked if "Run Immediately" is honoured by iOS).
- The intent starts a **session** and arms a WakeMission AlarmKit alarm. The sound is `.default` (the system alarm tone), so it matches Apple's own alarm.
- The user opens the app via the alarm's button, completes the missions, and the session ends.

## 2. State and data
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
Clock alarm stopped ─▶ Shortcuts automation ─▶ StartWakeMissionsIntent (background)
     WakeFlow.start(): RingingStore.begin(); AlarmService.armNext(after: ringMode.rearmDelay)
         ... delay ...
WakeMission alarm fires (system alert, default tone)
     user taps Start Mission / Wake Up ─▶ OpenAppFromAlarmIntent (openAppWhenRun)
         WakeFlow.rearm(): arm the NEXT alarm (only if the session still exists)
     app opens ─▶ AppState.consumePending() ─▶ missions full-screen
     user dismisses without finishing, or kills the app ─▶ the armed alarm fires again after `delay`
all missions done ─▶ AppState.completeWakeUp(): cancelAll(); RingingStore.clear()
```
Rules:
1. **AlarmKit buttons dismiss the alarm they belong to.** The only way to keep ringing is to always have the next alarm already armed. At most one WakeMission alarm is pending at a time.
2. **Closing the app cannot be prevented by iOS.** It is handled by the pending alarm being system-owned: it fires even if the app is killed. When the user stops it, the intent re-arms the next one and launches the app.
3. In "every N seconds" mode the alarm also rings while the user is doing missions (each dismissal re-arms). "Continuous" shortens the gap to 2 s.
4. Cold launch safe: all hand-off goes through `RingingStore`, never in-memory.
5. Completion cancels the pending alarm and clears the session.
6. Min delay for `.fixed` alarms in AlarmKit is untested – verify 2 s / 5 s on device.

## 4. Missions
All missions call `onCompleted` **exactly once**; `MissionCoordinator` also ignores completions for a non-current step.

### Typing
Phrase pool by difficulty. `TypingValidator`: case-insensitive, smart punctuation normalised, whitespace collapsed. Live feedback (green prefix, red border on mismatch). A change adding more than 1 character at once (paste) is rejected. Completes automatically.

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
System colours, fonts, grouped `List`, large title, light/dark follows the system, orange accent (as in Clock).
- **Home** (`HomeView`): Permission row; Missions (→ `MissionSelectorView`); "Ring again" picker; Setup (→ `ShortcutsGuideView`, "Try it now").
- **Missions**: add/delete/reorder (Edit), difficulty menu, photo reference registration.
- **Connect to Clock**: numbered Shortcuts steps and an Open Shortcuts button.
- **Onboarding** (first launch): promise, how it works, permissions (AlarmKit required, Camera optional).
- **Wake-up flow**: full-screen cover with progress bar and the current mission.

## 6. Manual test matrix (physical iPhone)
| # | Scenario | Expected |
|---|---|---|
| 1 | "Try it now" | WakeMission alarm fires after ~5 s with the default system tone |
| 2 | Tap Start Mission, then lock the phone | alarm fires again after the ring delay |
| 3 | Tap Start Mission, then kill the app | alarm fires again after the ring delay |
| 4 | Finish all missions | no further alarm fires; session cleared |
| 5 | Real Clock alarm + Shortcuts automation, phone locked | stopping the Clock alarm triggers the WakeMission alarm |
| 6 | Silent switch / Focus | alarm still sounds |
| 7 | Typing: paste whole phrase | rejected |
| 8 | Photo: camera denied | falls back to math |
| 9 | Ring mode Continuous / 60 s | gap matches the setting |
| 10 | Ignore the alarm for 60 min | chain stops (session expires) |

## 7. Known risks
- Whether "Run Immediately" is available for the Alarm trigger on all iOS versions (incl. 27 beta) is unverified.
- AlarmKit may rate-limit or reject alarms scheduled only a few seconds ahead.
- If the automation is deleted or fails, a Clock alarm stopped by the user is not followed by missions (no way to detect this from the app).

## 8. Out of scope
Reading Clock alarms, per-alarm mission profiles, snooze, stats, widgets, Apple Watch.
