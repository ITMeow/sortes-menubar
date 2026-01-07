//
//  PermissionsManager.swift
//  SortBar
//

import Combine
import Foundation
import OSLog

/// A type that manages the permissions of the app.
@MainActor
final class PermissionsManager: ObservableObject {
    /// The state of the granted permissions for the app.
    enum PermissionsState {
        case missingPermissions
        case hasAllPermissions
        case hasRequiredPermissions
    }

    /// The state of the granted permissions for the app.
    @Published var permissionsState = PermissionsState.missingPermissions

    let accessibilityPermission: AccessibilityPermission

    let screenRecordingPermission: ScreenRecordingPermission

    let allPermissions: [Permission]

    private(set) weak var appState: AppState?

    private var cancellables = Set<AnyCancellable>()

    var requiredPermissions: [Permission] {
        allPermissions.filter { $0.isRequired }
    }

    init(appState: AppState) {
        self.appState = appState
        self.accessibilityPermission = AccessibilityPermission()
        self.screenRecordingPermission = ScreenRecordingPermission()
        self.allPermissions = [
            accessibilityPermission,
            screenRecordingPermission,
        ]
        configureCancellables()
    }

    private func configureCancellables() {
        var c = Set<AnyCancellable>()

        Publishers.Merge(
            accessibilityPermission.$hasPermission.mapToVoid(),
            screenRecordingPermission.$hasPermission.mapToVoid()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            guard let self else {
                return
            }
            let accessibilityHasPermission = accessibilityPermission.hasPermission
            let screenRecordingHasPermission = screenRecordingPermission.hasPermission

            Logger.permissionsManager.debug("Permission state check - Accessibility: \(accessibilityHasPermission), ScreenRecording: \(screenRecordingHasPermission)")

            if allPermissions.allSatisfy({ $0.hasPermission }) {
                Logger.permissionsManager.debug("All permissions granted")
                permissionsState = .hasAllPermissions
            } else if requiredPermissions.allSatisfy({ $0.hasPermission }) {
                Logger.permissionsManager.debug("Required permissions granted (limited mode available)")
                permissionsState = .hasRequiredPermissions
            } else {
                Logger.permissionsManager.debug("Missing required permissions")
                permissionsState = .missingPermissions
            }
        }
        .store(in: &c)

        cancellables = c
    }

    /// Stops running all permissions checks.
    func stopAllChecks() {
        for permission in allPermissions {
            permission.stopCheck()
        }
    }
}

// MARK: - Logger

private extension Logger {
    static let permissionsManager = Logger(category: "PermissionsManager")
}
