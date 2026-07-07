<div align="center">

# MacSpa

**A calm menu-bar companion for caring for your Mac.**

Guided cleaning that safely pauses your keyboard and trackpad while you wipe, plus a real, grounded read on your Mac's health. Everything stays on your device.

![platform](https://img.shields.io/badge/platform-macOS%2015%2B-black?logo=apple)
![swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![license](https://img.shields.io/badge/license-MIT-blue)

</div>

## Why it exists

Cleaning your keyboard or screen means dragging a cloth across live input: you smear the trackpad, trigger shortcuts, and type gibberish. MacSpa fixes exactly that. It throws up a full-screen "spa" overlay and blocks keyboard and trackpad input for the duration of a timed cleaning ritual, so you can wipe safely. An unlock shortcut ends it any time.

Around that core it adds a wellness score from your real cleaning history, a Mac Health panel built from genuine system signals, gentle reminders, and achievements, all on-device with nothing transmitted.

## Features

- **Guided cleaning with a safe input lock.** A full-screen overlay pauses keyboard and trackpad through timed per-device stages (keyboard, trackpad, display). Run the full ritual or a single device; durations are configurable.
- **Wellness.** A 0 to 100 score from your cleaning history (recency plus frequency), a mood face, and a menu-bar glyph.
- **Mac Health.** A second, grounded score from real signals: free storage, memory pressure, uptime, battery cycles and capacity, and reclaimable junk. Read-only, cached, manual rescan.
- **Achievements and history.** Milestones and a month-grouped timeline of every session.
- **Reminders.** Sunday-anchored local notifications: weekly, alternate-Sunday, or first-Sunday-of-month at 10 AM.
- **Global shortcuts.** Rebindable hot keys for start, unlock, and open.
- **Private by design.** SwiftData on-device only; JSON export and one-tap purge; nothing leaves your Mac.
- **Themeable.** Light, Dark, or Auto appearance and five brand accents that recolor the whole app live.
- **Accessible.** Honors Reduce Motion, Reduce Transparency, and Increased Contrast.

## Privacy and permissions

MacSpa requests Accessibility permission for one reason: to pause keyboard and trackpad input during a cleaning session (a CoreGraphics event tap requires it). Input is only blocked, never logged, read, or transmitted. Mac Health uses only user-level system APIs (no admin, no privileged helper) and changes nothing.

## Documentation

- **[Development guide](docs/DEVELOPMENT.md)** - tech stack, setup, running, testing, and architecture.
- **[Contributing](docs/CONTRIBUTING.md)** - how to propose and submit changes.

## Roadmap

Today's Mac Health is read-only measurement. The direction is to make it actionable, an open and transparent take on the cleaner and optimizer category without the dark patterns: performance (memory, maintenance, login items), storage clean-up (caches, DerivedData, snapshots), security (permissions, unsigned apps, FileVault), and monitoring (live gauges). See the [development guide](docs/DEVELOPMENT.md) for the design ground rules.

## License

[MIT](LICENSE) (c) cmxau.

Apple, the Apple logo, macOS, and SF Symbols are trademarks of Apple Inc. The Apple logo shown in-app is Apple's SF Symbol, used under the SF Symbols license for identification only. MacSpa is not affiliated with, endorsed by, or sponsored by Apple Inc.
