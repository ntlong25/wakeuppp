# WakeMission – Design Critique and Handoff

Reviewed from SwiftUI source, without screenshots or a running build. Layout and contrast below are reasoned or calculated, not measured on a device. No Figma file exists; the code is the source of truth.

## Part 1: Design critique

### Overall impression
The move to system lists was right, and Home already reads as an iOS settings screen. The biggest gaps were that nothing pushed the user to do the one setup step the app depends on, and that `.orange` text failed contrast in light mode, which appeared when the app stopped forcing dark.

### Usability
| Finding | Severity | Fix applied |
|---|---|---|
| "Connect to Clock" sat at the bottom of Home and nothing pointed to it after onboarding. Without it, missions never start | 🔴 Critical | "Finish setup" section at the top of Home until the user confirms |
| App cannot detect the automation | 🟡 Moderate | "I've Set This Up" stores the user's own confirmation, and the footer says so |
| Math Hard: `(14 × 12) − 30` at fixed 48 pt could wrap or overflow on narrow phones | 🔴 Critical | One line, `minimumScaleFactor(0.5)`, 44 pt base |
| Fixed 380/420 pt camera plus 64 pt keys risked overflow on 667 pt phones | 🔴 Critical | Camera uses `maxHeight: .infinity`, keys flex 52–64 pt, Typing scrolls |
| Home flashed "Open Settings" before the status check returned | 🟡 Moderate | `authorizationKnown`; warning shows only when actually denied |
| "Allowed" row was permanent noise | 🟢 Minor | Permission section appears only when there is a problem |
| Missions row showed a bare "2" | 🟡 Moderate | Shows "Typing, Math" |
| "Allow & Start" could be tapped twice | 🟢 Minor | Disabled while requesting |
| Page dots were invisible in light mode | 🟡 Moderate | `.indexViewStyle(.page(backgroundDisplayMode: .always))` |

### Visual hierarchy
- **First draw on Home:** previously the Permission row, which is the least useful item once granted. Now the unfinished setup, or missions and ring pace once set up.
- **Wake-up flow:** three stacked headers (screen title, orange tracked caps, headline) cost height at the moment a groggy user needs the task. Now one progress line and one `MissionHeader`.
- **Emphasis:** the task (phrase, expression, camera) is now the largest thing on each screen.

### Consistency
| Element | Issue | Fix |
|---|---|---|
| Radii | 10, 12, 16, 20, 24 mixed | `Radius.sm/md/lg`, continuous corners |
| Spacing | Ad hoc numbers | `Spacing.xs…xl` |
| Mission titles | Tracked caps are not an iOS pattern | `MissionHeader` |
| Button labels | Sentence and title case mixed | Title case for buttons |
| Maths signs | Hyphen beside `×` | Real minus `−` |
| Deprecated API | `cornerRadius`, `foregroundColor` | `continuousCorners`, `foregroundStyle` |

### Accessibility
- **Contrast (calculated):** `#FF9500` on white 2.2:1 fails; `#34C759` on `#F2F2F7` 2.0:1 fails. New light accent `#C93400` is 5.3:1 on white and 4.7:1 on `#F2F2F7`; dark accent `#FF9F0A` is 10.2:1 on black.
- **Colour alone:** errors were red only. Math now shows "Not quite. Try again.", Typing shows "Check your last few letters".
- **VoiceOver:** keypad icons and the shutter had no names; labels added, decorative icons hidden, step numbers grouped with their text.
- **Reduce Motion:** the wrong-answer shake is skipped.
- **Dynamic Type:** Math's expression and answer stay fixed-size by design; everything else uses text styles.

### What works well
- System `List`, large title and native picker on Home.
- Keypad layout suited to half-awake, one-handed use.
- Photo's plain status pill over the live camera.

### App icon
Kept the existing `AppIcon-1024.png` (commit `4e3c201`): 1024×1024, opaque, simple shape. The clock-with-check idea says "alarm you complete". It reads redder than the old `.orange` UI, so the new burnt-orange light accent actually sits closer to it. Optional later: check it at 60 pt on a real Home Screen, because the check mark is the smallest detail.

### Remaining recommendations
1. Check real screens on the smallest supported iPhone and with the largest text sizes.
2. Add a dark and tinted icon variant for iOS 26 Home Screen styles.

## Part 2: Handoff spec

### Design tokens
| Token | Value | Usage |
|---|---|---|
| `AccentColor` | light `#C93400`, dark `#FF9F0A` | Tint, fills, icons |
| `Color.onAccent` | `systemBackground` | Text and icons on accent fills (white in light, black in dark) |
| `Spacing.xs/sm/md/lg/xl` | 4 / 8 / 16 / 24 / 32 | All padding and gaps |
| `Radius.sm/md/lg` | 10 / 16 / 24 | Small chips / cards, keys / camera |
| Surface | `systemBackground`, `secondarySystemBackground` | Screen, cards |
| Key fills | `secondarySystemFill`, `tertiarySystemFill` | Digits, delete |
| Error | `Color.red` plus text | Never colour alone |
| Success | `Color.green` | Camera border only, never text |

`.orange` remains only in `AlarmService` as the system alert tint.

### Typography
| Role | Style |
|---|---|
| Mission title | `.title2.bold()` |
| Mission subtitle, step label | `.subheadline`, secondary |
| Phrase | `.title3` rounded semibold |
| Expression | 44 pt rounded bold, 1 line, scales to 50% |
| Answer | 36 pt rounded semibold, `monospacedDigit` |
| Hints | `.footnote` |

### Components
| Component | Props | Notes |
|---|---|---|
| `MissionHeader` | `title`, `subtitle` | Centred, header trait |
| `KeypadView` | digit, delete, submit callbacks | 3×4 grid, gap `sm`, height 52–64 |
| `continuousCorners(_:)` | radius | Use instead of `cornerRadius` |

### Screens
| Screen | Layout |
|---|---|
| Home | Grouped list: [Alarms are turned off]? · [Finish setup]? · Missions + Ring Again · [Connect to Clock]? + Test Wake-Up Flow |
| Connect to Clock | Numbered steps, then Open Shortcuts + I've Set This Up / Mark as Not Set Up |
| Onboarding | Three pages, pinned button, padding `lg` |
| Wake-up | Step label + progress, then mission fills the rest |

### States and interactions
| Element | State | Behaviour |
|---|---|---|
| Home alarm warning | Status unknown | Hidden |
| Home alarm warning | Denied | Section with Open Settings |
| Finish setup | `clockSetupDone == false` | Top section; moves to lower section when true |
| Onboarding button | Requesting | Disabled |
| Math answer | Empty / typing | "?" secondary / digits primary |
| Math answer | Wrong | Haptic, shake, red border, hint; hint clears on next key |
| Typing input | Mismatch | Red border and hint |
| Typing input | Pasted text | Rejected silently |
| Photo frame | Match | Green border |
| Photo footer | After 90 s | Bordered "Can't Scan? Solve Math Instead" |
| Reference | Camera denied | Message + Open Settings |

### Layout behaviour
Portrait only, iPhone only in practice. Minimum target height 667 pt. Camera absorbs spare height, keys compress to 52 pt, Typing scrolls above the keyboard.

### Edge cases
- **No missions:** Home shows "Quick math"; the flow runs one easy problem.
- **Long summary:** `LabeledContent` truncates on its own.
- **Camera starting:** `secondarySystemBackground` placeholder behind the preview.
- **Empty key:** Submit with no digits does nothing.

### Motion
| Element | Trigger | Animation |
|---|---|---|
| Mission | Step change | Slide in from trailing, out to leading |
| Answer box | Wrong answer | 300 ms shake, skipped with Reduce Motion |
| Progress | Step change | Spring |
| Done overlay | All complete | Fade, 1.2 s hold |

### Accessibility notes
Focus order follows reading order. Keys are named ("Delete", "Submit answer"), the shutter is "Take reference photo", progress exposes "N percent". Minimum touch target 44 pt; keys are at least 52 pt.
