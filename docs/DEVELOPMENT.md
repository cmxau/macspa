# Development guide

Everything you need to build, run, test, and understand MacSpa.

## Tech stack

- **Language:** Swift 6 (strict concurrency).
- **UI:** SwiftUI, with AppKit where macOS needs it (menu-bar item, borderless session windows, event tap, appearance).
- **Persistence:** SwiftData, on-device only.
- **System APIs:** CoreGraphics (event tap for the input lock), IOKit (battery), Mach and sysctl (memory, uptime), UserNotifications (reminders), Carbon (`RegisterEventHotKey`) for global hot keys.
- **Project generation:** [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`.
- **No third-party runtime dependencies.**

## Prerequisites

- macOS 15 or newer
- Xcode 16 or newer (Swift 6)
- XcodeGen: `brew install xcodegen`

## Setup

The Xcode project is generated, not committed. After cloning:

```bash
xcodegen generate
```

Re-run this whenever you add or remove a source file.

## Run

```bash
open MacSpa.xcodeproj   # then press Cmd+R
```

Or headless:

```bash
xcodebuild -project MacSpa.xcodeproj -scheme MacSpa -configuration Debug \
  -destination 'platform=macOS' build
```

On first launch, grant Accessibility in System Settings, Privacy and Security, Accessibility. The in-session badge turns green once input is actually locked. Because a rebuilt debug binary is a new binary to macOS, the grant may need re-applying per build; running from a stable path such as `/Applications` avoids that.

## Test

```bash
xcodebuild -project MacSpa.xcodeproj -scheme MacSpa -destination 'platform=macOS' test
```

Unit tests cover the pure logic: wellness scoring, mood, and band boundaries; the Sunday reminder date math; duration formatting; and the health score mapping plus a live snapshot sanity check. CI runs build and test on every push and pull request (see `.github/workflows/ci.yml`).

## Architecture

Plain SwiftUI, SwiftData, and AppKit. One folder per surface, one service per responsibility.

```
MacSpa/
  App/            @main scene, AppState (@Observable), AppDelegate, hot-key bridge
  Components/     AppLogo, DeviceArt, GlassCard, RingView, MoodFace
  DesignSystem/   SpaColors (palette and accent), Primitives, ViewModifiers, AppTheme
  Features/       One folder per surface: Dashboard, GuidedCleaning, Health,
                  History, Achievements, Session, Settings, Onboarding, MenuBar, Shell
  Models/         SwiftData @Model types and CleaningDurations
  Services/       EventTapService (input lock), WellnessService, SystemHealthService,
                  ReminderService, SoundService, HotKeyService, LoginItemService, and more
Tests/            XCTest unit tests (pure logic)
```

Key services:

| Service | Responsibility |
| --- | --- |
| `EventTapService` | Blocks input during a session; watches for the unlock combo. |
| `WellnessService` | Score, mood, and band from cleaning history. |
| `SystemHealthService` | Reads storage, memory, uptime, battery, and junk into a composite health score. |
| `ReminderService` | Sunday-anchored local notifications. |

## Design ground rules

The roadmap moves Mac Health from measurement toward action (cleanup, maintenance). Any mutating action must ship with:

- a plain-English description of what it does and what could break,
- a confirmation for anything destructive,
- honest expectations (for example, reindexing Spotlight slows search for a while),
- admin actions via a native password prompt (`AppleScript` or `SMAppService`), never a silent privileged helper unless a contributor wires one in deliberately.

## Distribution

The repo builds an ad-hoc-signed app. For sharing beyond your own Mac you will want an Apple Developer ID, hardened runtime, and notarization (`xcrun notarytool`); without it, Gatekeeper requires right-click then Open on first launch.
