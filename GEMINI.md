# SortBar Project Context

## Project Overview

SortBar is a powerful macOS menu bar management tool designed to hide, show, and arrange menu bar items. It features a modern SwiftUI interface, advanced customization options (menu bar tint, shadow, border), and hotkey support.

*   **Platform:** macOS 14.0 (Sonoma) or later.
*   **Language:** Swift 5.9+.
*   **Frameworks:** SwiftUI, AppKit, Combine.
*   **Architecture:** The project follows a feature-based architecture with a centralized `AppState` and feature-specific managers (e.g., `MenuBarManager`, `SettingsManager`).

## Building and Running

### Prerequisites
*   macOS 14.0+
*   Xcode 15.0+
*   Homebrew (for SwiftLint, optional but recommended)

### Steps
1.  **Open the Project:**
    Open `SortBar.xcodeproj` in Xcode.
    ```bash
    open SortBar.xcodeproj
    ```
2.  **Configure Signing:**
    *   Navigate to the project settings -> "SortBar" target -> "Signing & Capabilities".
    *   Select your Development Team.
3.  **Build and Run:**
    *   Select the "SortBar" scheme.
    *   Press `Cmd+R` or click the Play button.

### Permissions
The app requires specific system permissions to function correctly:
*   **Accessibility:** Required for interacting with menu bar items.
*   **Screen Recording:** Required for capturing menu bar item images to render them in the configuration UI and custom bar.

## Project Structure

*   **`SortBar.xcodeproj`**: Main Xcode project file.
*   **`SortBar/`**: Source code directory.
    *   **`Main/`**: Application entry point and lifecycle management.
        *   `SortBarApp.swift`: `@main` entry point.
        *   `AppDelegate.swift`: NSApplicationDelegate implementation.
        *   `AppState.swift`: Centralized application state.
    *   **`MenuBar/`**: Core logic for menu bar item management.
        *   `MenuBarManager.swift`: Manages sections and items.
        *   `Appearance/`: Menu bar styling logic.
    *   **`UI/`**: SwiftUI views and custom components.
        *   `SortBarBar/`: The floating bar UI for hidden items.
        *   `LayoutBar/`: Drag-and-drop layout editor.
        *   `Settings/`: Settings window and panes.
    *   **`Events/`**: Low-level event handling (mouse, keyboard).
    *   **`Bridging/`**: Bridges to private macOS APIs needed for advanced menu bar manipulation.
    *   **`Utilities/`**: Helper extensions, constants, and shared utilities.

## Development Conventions

*   **SwiftLint:** The project uses SwiftLint for code formatting and style enforcement. Run `swiftlint` to check for issues.
*   **Architecture:**
    *   Use `ObservableObject` and `@Published` for state management.
    *   Split complex logic into specific "Managers" (e.g., `PermissionsManager`, `UpdatesManager`).
    *   Keep Views declarative and focused on UI; move logic to ViewModels or Managers.
*   **Private APIs:** Be cautious when modifying code in `Bridging/` as it relies on private system APIs which may change between macOS versions.

## Troubleshooting

*   **"SortBar needs permission...":** Ensure the app is checked in *System Settings > Privacy & Security > Accessibility* AND *Screen Recording*. If issues persist, remove the entry and re-add it.
*   **Icons not showing:** Verify Screen Recording permissions.
*   **Signing errors:** Ensure a valid Development Team is selected in Xcode.
