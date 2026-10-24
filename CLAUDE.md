# CLAUDE.md

WakeMission: native iOS alarm app. An alarm only stops after the user completes wake-up missions (Typing, Math, Photo). Swift 6 (strict concurrency `complete`), SwiftUI, SwiftData, AlarmKit, App Intents, Vision, AVFoundation. Target **iOS 26 / Xcode 26** (AlarmKit requirement).

## Environment caveat
The repo is often edited on Windows, where there is no Swift toolchain. Code cannot be compiled or run there. Keep logic in small pure types (`Services/Logic`, generators) so it is unit-testable on a Mac, and do a careful read-through for Swift 6 concurrency errors before finishing.

## Commands (macOS)
```bash
brew install xcodegen
xcodegen generate                      # creates WakeMission.xcodeproj from project.yml (not committed)
xcodebuild test -scheme WakeMission -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
AlarmKit, lock screen, Silent/Focus, and camera behavior must be tested on a **physical iPhone**.

## Docs
- `docs/SPEC.md` – source of truth for behavior. Update it with any behavior change.
- `docs/PLAN.md` – roadmap and status.

## Architecture
- `App/` – `WakeMissionApp` (ModelContainer, ringing full-screen cover), `AppState` (auth, ringing state, pending-ring consumption).
- `Models/` – SwiftData: `AlarmItem`, `MissionItem`, `AlarmSessionRecord`.
- `Services/Alarm` – `AlarmService` wraps `AlarmManager`; schedules main alarm + backup "nag" alarms.
- `Services/Intents` – App Intents run by AlarmKit buttons; they only write to `RingingStore` (UserDefaults) because the app may be cold-launched and in-memory notifications are lost.
- `Services/Audio` – `AlarmAudioPlayer` loops a synthesized tone (no bundled assets).
- `Services/Camera`, `Services/Vision` – frame capture, FeaturePrint matching, classification fallback, anti-cheat.
- `Features/` – UI per screen; `Features/Missions/Common/MissionCoordinator` sequences missions.

## Rules and gotchas
- **AlarmKit stop and secondary buttons both dismiss the system alarm.** Never assume it keeps ringing. After the app opens it plays its own audio, and backup nag alarms re-fire until all missions pass.
- Finishing an alarm must never `cancel` the repeating schedule; use `AlarmService.finishOccurrence`.
- Mission completion callbacks must fire exactly once.
- Never allow a state where the user cannot stop the alarm (camera denied, no reference photo, 10-minute safety cutoff) – always provide a fallback.
- No photo library selection for the Photo mission (anti-cheat); live camera only.
- No snooze (product philosophy).
- Swift 6: UI types are `@MainActor`; camera/Vision callbacks hop to main explicitly; don't mutate `@State` from `@Sendable` closures off-main.
- UI language: English strings; docs may be Vietnamese or English.
