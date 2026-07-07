# Contributing

Contributions are welcome. This is a small, dependency-free SwiftUI app; keep it that way.

## Getting started

1. Fork and clone the repo.
2. Generate the project: `xcodegen generate` (see the [development guide](DEVELOPMENT.md)).
3. Create a branch off `main`.

## Ground rules

- **Stay dependency-free.** No third-party runtime packages.
- **Swift 6, strict concurrency clean.** No new warnings.
- **Test the logic.** Add or extend XCTest coverage for any non-trivial logic. `xcodebuild ... test` must pass locally and in CI.
- **Match the design system.** Use `SpaColors`, `Primitives`, and the single solid card style; do not introduce one-off colors or surfaces.
- **No em dashes** in code, comments, or docs; use plain punctuation.
- **Respect privacy and safety.** Nothing leaves the device. Any action that changes system state needs a clear description, a confirmation when destructive, and a native permission prompt rather than a silent privileged helper.

## Commits and pull requests

- Write focused, modular commits with clear messages (Conventional Commits style is used here: `feat`, `fix`, `chore`, `test`, `docs`, `ci`).
- Open a pull request against `main` with a short description of the change and why.
- CI must be green before merge.

## Reporting bugs and ideas

Use GitHub issues. The in-app About screen also links pre-filled bug and feature templates.
