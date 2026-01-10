# Repository Guidelines

## Project Structure & Module Organization

- `SortBar.xcodeproj` is the Xcode project entry point.
- `SortBar/` contains all Swift sources. Core areas include `Main/` (app entry and state), `MenuBar/` (menu bar logic), `UI/` (SwiftUI views), `Settings/`, `Permissions/`, `Hotkeys/`, `Bridging/` (private API shims), and `Utilities/`.
- `SortBar/Assets.xcassets/` stores the app icon and UI images.
- `SortBar/Resources/` holds localized strings and acknowledgements.
- `Resources/` contains design/reference assets (icons, gifs, figma).

## Build, Test, and Development Commands

- `open SortBar.xcodeproj` opens the project in Xcode.
- Xcode build/run: `Cmd+B` (build), `Cmd+R` (run). Use the `SortBar` scheme and `My Mac` target.
- Linting: `swiftlint` (run manually) or `swiftlint --fix` for auto-fixes.

## Coding Style & Naming Conventions

- Swift 5.9+ with SwiftUI/AppKit. Indentation is 4 spaces; tabs are disallowed (SwiftLint enforced).
- File headers are required via SwiftLint, using the legacy pattern:
  ```
  //
  //  <Filename>
  //  Ice
  //
  ```
- Multiline collections and parameters must include trailing commas.
- Manager types follow `*Manager` naming and are held in `AppState` for shared state.
- Use the Logger pattern: `private extension Logger { static let foo = Logger(category: "Foo") }`.

## Testing Guidelines

- No automated test targets are present in this repo. Validate changes by running the app and exercising:
  menu bar layout/appearance, hotkeys, permissions flow, and Settings.
- If adding tests, use standard Xcode naming (`SortBarTests`, `testFeatureName()`).

## Commit & Pull Request Guidelines

- Commit history favors short, single-line summaries (imperative or sentence case). Prefixes like `fix:` or `update:` are acceptable.
- PRs should include: summary, motivation, verification steps, and screenshots/screen recordings for UI changes.
- Call out changes under `SortBar/Bridging/` (private APIs) and any new permissions or signing steps.

## Configuration & Permissions

- SortBar requires Accessibility and Screen Recording permissions; note any updates that touch these flows.
- Code signing is required to run locally; set your team in Xcode > Signing & Capabilities.
