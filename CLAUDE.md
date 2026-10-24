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

## Info.plist gotcha
`xcodegen generate` regenerates `WakeMission/Info.plist` from `info.properties` in `project.yml`, overwriting hand edits. Add any plist key (e.g. `NSAlarmKitUsageDescription`, `NSCameraUsageDescription`) to `project.yml`, not just the plist. A missing AlarmKit key makes `requestAuthorization()` throw.

## Docs
- `docs/SPEC.md` – source of truth for behavior. Update it with any behavior change.
- `docs/PLAN.md` – roadmap and status.

## Architecture
Concept: alarms live in Apple's Clock app. A Shortcuts automation ("alarm is stopped") runs `StartWakeMissionsIntent`, which arms a system-owned AlarmKit alarm; stopping it re-arms the next one until the missions are completed. No SwiftData; state is in UserDefaults.
- `App/` – `WakeMissionApp`, `AppState` (auth, whether the mission cover is shown, completion).
- `Models/` – `WakeSettings` (missions + `RingMode`, `SettingsStore`), `MissionModels`.
- `Services/Alarm` – `AlarmService`: arms/cancels the single pending WakeMission alarm (`.default` system sound).
- `Services/Intents` – `StartWakeMissionsIntent` (Shortcuts), `OpenAppFromAlarmIntent` (AlarmKit buttons), `WakeFlow`. They only touch `RingingStore`/`AlarmService`, never UI, because the app may be cold-launched.
- `Services/Logic` – pure, unit-tested: `RingingStore`, `TypingValidator`, `PhotoMatchDecider`.
- `Services/Camera`, `Services/Vision` – frame capture, FeaturePrint matching, classification fallback.
- `Features/` – `Home` (settings-style root + Shortcuts guide), `Settings` (mission list), `AlarmRinging/WakeUpContainerView`, `Missions/*`, `Onboarding`.

## Rules and gotchas
- **AlarmKit buttons dismiss their alarm.** Ringing continues only because the next alarm is armed before/when the previous one is dismissed. Keep at most one pending WakeMission alarm; completion must call `AlarmService.cancelAll()` then `RingingStore.clear()`.
- The app cannot read or edit Clock alarms and cannot prevent being closed; the system-owned pending alarm is the safeguard.
- Mission completion callbacks must fire exactly once.
- Never allow a state where the user cannot finish (camera denied, no reference photo): always provide a fallback (math).
- No photo library selection for the Photo mission; live camera only.
- No snooze; no Stats screen.
- UI must look native: system colours/fonts, grouped lists, follow light/dark. Don't hard-code black backgrounds or white text.
- Swift 6: UI types are `@MainActor`; camera/Vision callbacks hop to main explicitly; don't mutate `@State` from `@Sendable` closures off-main.
- UI language: English strings; docs may be Vietnamese or English.
