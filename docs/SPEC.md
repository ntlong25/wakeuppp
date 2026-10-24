# WakeMission – Technical Spec (v1.0)

Product rule: **an alarm is only turned off by completing its missions.** No snooze.

Platform: iOS 26+, Swift 6 (strict concurrency), SwiftUI, SwiftData, AlarmKit, App Intents, Vision, AVFoundation.

## 1. Data model (SwiftData)

### AlarmItem
| field | type | notes |
|---|---|---|
| id | UUID (unique) | also the AlarmKit alarm id |
| time | Date | only hour/minute are meaningful; seconds are normalised to 0 on save |
| label | String | |
| repeatDays | [Int] | 1=Sun … 7=Sat; empty = one-shot |
| isEnabled | Bool | one-shot alarms are set to false after completion |
| soundName | String | `AlarmTone` raw value (in-app ringing tone) |
| missions | [MissionItem] | cascade delete, ordered by `order` |

### MissionItem
`typeRaw` (typing/math/photo), `order`, `difficultyRaw` (easy/medium/hard), `configurationData: Data?` (JSON `PhotoMissionConfig` for photo missions).

`PhotoMissionConfig { featurePrint: Data, thumbnail: Data }` – `featurePrint` is a secure-coded archive of `VNFeaturePrintObservation`.

### AlarmSessionRecord
`id, alarmId, scheduledAt, triggeredAt, completedAt?, missionsCompleted, durationSeconds, success`. Created when ringing starts with `success=false`; updated on completion. A record that stays `success=false` is an abandoned/failed wake-up.

### Editing drafts
The editor works on value-type `MissionDraft` (id, type, difficulty, configurationData). On save the alarm's missions are replaced (old ones deleted) – no orphans, and Cancel never mutates stored data.

## 2. Alarm lifecycle

```
Scheduled ──fire──▶ System alert (AlarmKit)
   user taps Start Mission / Stop ──▶ OpenAppFromAlarmIntent.perform()
        1. RingingStore.begin(alarmId)       (persisted; first time only)
        2. AlarmService.scheduleNags(parent) (first time only)
   app foreground ──▶ AppState.consumePending() ──▶ Ringing (own audio + missions)
   all missions done ──▶ AppState.completeAlarm()
        stop audio · cancelNags · record success · finishOccurrence · RingingStore.clear
```

Rules:
1. **AlarmKit buttons dismiss the system alarm.** The app therefore (a) plays its own looping tone while ringing and (b) schedules **6 nag alarms at +3, +6, … +18 min** (fixed-date AlarmKit alarms using the same intent). They are cancelled on completion. If the user falls back asleep after tapping the button, a nag fires.
2. **Cold launch safe**: the intent writes `RingingSession` to UserDefaults. `AppState` consumes it on app start and every time the scene becomes active. A session older than 60 min is discarded.
3. **Resume**: if the app is killed mid-missions and reopened (or a nag is tapped), the active `RingingSession` restarts missions for the same record (`startedAt` and `recordId` preserved).
4. **Scheduling**: one-shot → `.fixed(nextFireDate)`; repeating → `.relative(.weekly(days))`. `nextFireDate` is computed by `AlarmScheduleMath` (testable).
5. **finishOccurrence**: one-shot → `isEnabled=false` and cancel; repeating → leave AlarmKit schedule untouched. Never cancel a repeating alarm on completion.
6. **Audio safety**: in-app audio auto-stops after 10 minutes; missions remain required. (Nags continue to 18 min.)
7. No snooze anywhere.

## 3. Missions

All missions call `onCompleted` **exactly once**. `MissionCoordinator` additionally ignores completions for a non-current step.

### Typing
- Phrase pool by difficulty (easy ≤ 20 chars, medium 40–60, hard 70+).
- Validation (`TypingValidator`): case-insensitive; normalises curly quotes/dashes and collapses whitespace; trims ends.
- Live feedback: correct prefix green, remaining gray, mismatch highlights red border.
- Anti-paste: an input change that adds more than 1 character at once is rejected.
- Completes automatically on match (no extra button).

### Math
- Easy: `a ± b` (2-digit). Medium: add/sub/`a×b` (≤12×15). Hard: `(a×b) − c` with `c < a×b`, always ≥ 0.
- All answers are non-negative integers (keypad has no minus).
- Problems required: easy 2, medium 3, hard 4. Wrong answer: shake + haptic, input cleared.

### Photo
- Live camera only (no library). Back camera, 640×480 BGRA, `alwaysDiscardsLateVideoFrames`, analysed at ≤ 5 fps.
- **Strategy A – reference match** (when a reference photo is registered): `VNGenerateImageFeaturePrintRequest` per frame; `computeDistance` to the stored print. Match if `distance < threshold` where threshold = easy 0.55 / medium 0.45 / hard 0.35 (**to be calibrated on device**).
- **Strategy B – fallback** (no reference): `VNClassifyImageRequest`, labels containing sink/washbasin/basin/faucet/bathroom/toilet with confidence ≥ 0.70.
- **Debounce** (`PhotoMatchDecider`): success after 4 consecutive matching frames; any miss resets.
- **Anti-cheat**: mean luminance of the last 10 frames must vary (max−min ≥ 0.004) – a perfectly static feed (covered lens / frozen image) cannot pass. Heuristic, not security.
- **Never stuck**: camera permission denied → immediately fall back to a Math mission; after 90 s without success a "Can't scan? Solve math instead" button appears.
- Camera session stops on disappear and on success.

### Registration (editor)
`ReferenceRegistrationView`: live preview, "Capture" button grabs the next frame, stores feature print + JPEG thumbnail in the draft. Requires camera permission; shows a settings hint when denied.

## 4. Permissions and onboarding
First launch shows 3 pages (promise, how it works, permissions). Permissions: AlarmKit (required for scheduling), Camera (optional; photo mission falls back). If AlarmKit is denied the list shows a banner with an Open Settings button and scheduling is skipped.

## 5. Stats
- `StreakCalculator.currentStreak`: consecutive calendar days with ≥ 1 successful session, counting back from today (if none today, from yesterday so the streak is not lost before the user wakes up).
- Weekly chart: successes per day for the last 7 days.
- Average wake time: mean time-of-day of `completedAt` for successes in the last 30 days.

## 6. UI notes
Dark theme, orange accent. Tab bar: Alarms, Stats. List shows the soonest enabled alarm (repeat-aware countdown) and a debug "Test alarm" button (fires in 1–2 min).

## 7. Acceptance criteria / manual test matrix (physical iPhone)
| # | Scenario | Expected |
|---|---|---|
| 1 | Silent switch ON, locked, alarm fires | system alarm sounds |
| 2 | Focus ON | alarm breaks through |
| 3 | App force-killed | alarm fires; tapping Start Mission launches into missions |
| 4 | Tap Start Mission, then lock phone and do nothing | nag fires after 3 min |
| 5 | Complete all missions | audio stops, nags cancelled (none fire), record success |
| 6 | Repeating alarm completed | next week's occurrence still scheduled |
| 7 | One-shot completed | toggle shows off |
| 8 | Kill app mid-mission, reopen | missions resume |
| 9 | Camera denied with photo mission | falls back to math |
| 10 | Typing: paste whole phrase | rejected |
| 11 | Photo: cover lens / static image | never completes |
| 12 | Alarm across midnight / DST | fires at local wall-clock time |

## 8. Out of scope for 1.0
Snooze, custom sounds import, Apple Watch, widgets, iCloud sync.
