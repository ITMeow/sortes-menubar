//
//  MenuBarItem.swift
//  SortBar
//

import Cocoa

// MARK: - MenuBarItem

/// A representation of an item in the menu bar.
struct MenuBarItem {
    /// The item's window.
    let window: WindowInfo

    /// The menu bar item info associated with this item.
    let info: MenuBarItemInfo

    /// The identifier of the item's window.
    var windowID: CGWindowID {
        window.windowID
    }

    /// The frame of the item's window.
    var frame: CGRect {
        window.frame
    }

    /// The title of the item's window.
    var title: String? {
        window.title
    }

    /// A Boolean value that indicates whether the item is on screen.
    var isOnScreen: Bool {
        window.isOnScreen
    }

    /// A Boolean value that indicates whether the item can be moved.
    var isMovable: Bool {
        let immovableItems = Set(MenuBarItemInfo.immovableItems)
        return !immovableItems.contains(info)
    }

    /// A Boolean value that indicates whether the item can be hidden.
    var canBeHidden: Bool {
        let nonHideableItems = Set(MenuBarItemInfo.nonHideableItems)
        return !nonHideableItems.contains(info)
    }

    /// The process identifier of the application that owns the item.
    var ownerPID: pid_t {
        window.ownerPID
    }

    /// The name of the application that owns the item.
    ///
    /// This may have a value when ``owningApplication`` does not have
    /// a localized name.
    var ownerName: String? {
        window.ownerName
    }

    /// The application that owns the item.
    var owningApplication: NSRunningApplication? {
        window.owningApplication
    }

    /// A name associated with the item that is suited for display to
    /// the user.
    var displayName: String {
        var fallback: String { "Unknown" }
        guard let owningApplication else {
            return ownerName ?? title ?? fallback
        }
        var bestName: String {
            owningApplication.localizedName ??
            ownerName ??
            owningApplication.bundleIdentifier ??
            fallback
        }
        guard let title else {
            return bestName
        }
        // by default, use the application name, but handle a few special cases
        return switch MenuBarItemInfo.Namespace(owningApplication.bundleIdentifier) {
        case .controlCenter:
            switch title {
            case "AccessibilityShortcuts": "Accessibility Shortcuts"
            case "BentoBox": bestName // Control Center
            case "FocusModes": "Focus"
            case "KeyboardBrightness": "Keyboard Brightness"
            case "MusicRecognition": "Music Recognition"
            case "NowPlaying": "Now Playing"
            case "ScreenMirroring": "Screen Mirroring"
            case "StageManager": "Stage Manager"
            case "UserSwitcher": "Fast User Switching"
            case "WiFi": "Wi-Fi"
            default: title
            }
        case .systemUIServer:
            switch title {
            case "TimeMachine.TMMenuExtraHost"/*Sonoma*/, "TimeMachineMenuExtra.TMMenuExtraHost"/*Sequoia*/: "Time Machine"
            default: title
            }
        case MenuBarItemInfo.Namespace("com.apple.Passwords.MenuBarExtra"): "Passwords"
        default:
            bestName
        }
    }

    /// A Boolean value that indicates whether the item is currently
    /// in the menu bar.
    var isCurrentlyInMenuBar: Bool {
        let list = Set(Bridging.getWindowList(option: .menuBarItems))
        return list.contains(windowID)
    }

    /// A string to use for logging purposes.
    var logString: String {
        String(describing: info)
    }

    /// Creates a menu bar item from the given window.
    ///
    /// This initializer does not perform any checks on the window to ensure that
    /// it is a valid menu bar item window. Only call this initializer if you are
    /// certain that the window is valid.
    private init(uncheckedItemWindow itemWindow: WindowInfo, index: Int = 0) {
        self.window = itemWindow
        self.info = MenuBarItemInfo(uncheckedItemWindow: itemWindow).withIndex(index)
    }

    /// Creates a menu bar item with the given info (used for updating index).
    private init(window: WindowInfo, info: MenuBarItemInfo) {
        self.window = window
        self.info = info
    }

    /// Returns a copy of this item with the given index.
    func withIndex(_ newIndex: Int) -> MenuBarItem {
        MenuBarItem(window: window, info: info.withIndex(newIndex))
    }

    /// Creates a menu bar item.
    ///
    /// The parameters passed into this initializer are verified during the menu
    /// bar item's creation. If `itemWindow` does not represent a menu bar item,
    /// the initializer will fail.
    ///
    /// - Parameter itemWindow: A window that contains information about the item.
    init?(itemWindow: WindowInfo) {
        guard itemWindow.isMenuBarItem else {
            return nil
        }
        self.init(uncheckedItemWindow: itemWindow)
    }

    /// Creates a menu bar item with the given window identifier.
    ///
    /// The parameters passed into this initializer are verified during the menu
    /// bar item's creation. If `windowID` does not represent a menu bar item,
    /// the initializer will fail.
    ///
    /// - Parameter windowID: An identifier for a window that contains information
    ///   about the item.
    init?(windowID: CGWindowID) {
        guard let window = WindowInfo(windowID: windowID) else {
            return nil
        }
        self.init(itemWindow: window)
    }
}

// MARK: MenuBarItem Getters
extension MenuBarItem {
    /// Returns an array of the current menu bar items in the menu bar on the given display.
    ///
    /// - Parameters:
    ///   - display: The display to retrieve the menu bar items on. Pass `nil` to return the
    ///     menu bar items across all displays.
    ///   - onScreenOnly: A Boolean value that indicates whether only the menu bar items that
    ///     are on screen should be returned.
    ///   - activeSpaceOnly: A Boolean value that indicates whether only the menu bar items
    ///     that are on the active space should be returned.
    static func getMenuBarItems(on display: CGDirectDisplayID? = nil, onScreenOnly: Bool, activeSpaceOnly: Bool) -> [MenuBarItem] {
        var option: Bridging.WindowListOption = [.menuBarItems]

        var titlePredicate: (MenuBarItem) -> Bool = { _ in true }
        var boundsPredicate: (CGWindowID) -> Bool = { _ in true }

        if onScreenOnly {
            option.insert(.onScreen)
        }
        if activeSpaceOnly {
            option.insert(.activeSpace)
            titlePredicate = { $0.title != "" }
        }
        if let display {
            let displayBounds = CGDisplayBounds(display)
            boundsPredicate = { windowID in
                guard let windowFrame = Bridging.getWindowFrame(for: windowID) else {
                    return false
                }
                return displayBounds.intersects(windowFrame)
            }
        }

        let items = Bridging.getWindowList(option: option).lazy
            .filter(boundsPredicate)
            .compactMap { windowID in
                MenuBarItem(windowID: windowID)
            }
            .filter(titlePredicate)
            .sortedByOrderInMenuBar()

        // Assign unique indices to items with duplicate namespace:title combinations
        return assignUniqueIndices(to: items)
    }

    /// Assigns unique indices to items that have the same namespace:title combination.
    private static func assignUniqueIndices(to items: [MenuBarItem]) -> [MenuBarItem] {
        // Count occurrences of each namespace:title combination
        var counts = [String: Int]()
        for item in items {
            let key = "\(item.info.namespace.rawValue):\(item.info.title)"
            counts[key, default: 0] += 1
        }

        // Only process if there are duplicates
        let hasDuplicates = counts.values.contains { $0 > 1 }
        guard hasDuplicates else {
            return items
        }

        // Assign indices to duplicates
        var currentIndex = [String: Int]()
        return items.map { item in
            let key = "\(item.info.namespace.rawValue):\(item.info.title)"
            guard counts[key, default: 0] > 1 else {
                return item
            }
            let index = currentIndex[key, default: 0]
            currentIndex[key] = index + 1
            return item.withIndex(index)
        }
    }
}

// MARK: MenuBarItem: Equatable
extension MenuBarItem: Equatable {
    static func == (lhs: MenuBarItem, rhs: MenuBarItem) -> Bool {
        lhs.window == rhs.window
    }
}

// MARK: MenuBarItem: Hashable
extension MenuBarItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(window)
    }
}

// MARK: MenuBarItemInfo Unchecked Item Window Initializer
private extension MenuBarItemInfo {
    /// Creates a simplified item from the given window.
    ///
    /// This initializer does not perform any checks on the window to ensure that
    /// it is a valid menu bar item window. Only call this initializer if you are
    /// certain that the window is valid.
    init(uncheckedItemWindow itemWindow: WindowInfo) {
        if let bundleIdentifier = itemWindow.owningApplication?.bundleIdentifier {
            self.namespace = Namespace(bundleIdentifier)
        } else {
            self.namespace = .null
        }
        if let title = itemWindow.title {
            self.title = title
        } else {
            self.title = ""
        }
        self.index = 0
    }
}
