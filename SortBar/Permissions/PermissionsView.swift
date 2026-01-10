//
//  PermissionsView.swift
//  SortBar
//

import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var permissionsManager: PermissionsManager
    @Environment(\.openWindow) private var openWindow

    private var continueButtonText: LocalizedStringKey {
        if case .hasRequiredPermissions = permissionsManager.permissionsState {
            "Continue in Limited Mode"
        } else {
            "Continue"
        }
    }

    private var continueButtonForegroundStyle: some ShapeStyle {
        if case .hasRequiredPermissions = permissionsManager.permissionsState {
            AnyShapeStyle(.yellow)
        } else {
            AnyShapeStyle(.primary)
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            headerView
            
            VStack(spacing: 20) {
                Text("To function correctly, SortBar needs access to accessibility features and screen recording.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                permissionsGroupStack
            }

            footerView
        }
        .padding(40)
        .frame(width: 500)
        .readWindow { window in
            guard let window else { return }
            window.styleMask.remove([.closable, .miniaturizable])
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
        }
    }

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 16) {
            if let nsImage = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            }
            Text("Welcome to SortBar")
                .font(.system(size: 28, weight: .bold))
        }
    }

    @ViewBuilder
    private var permissionsGroupStack: some View {
        VStack(spacing: 16) {
            ForEach(permissionsManager.allPermissions) { permission in
                permissionRow(permission)
            }
        }
    }

    @ViewBuilder
    private var footerView: some View {
        HStack(spacing: 16) {
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                guard let appState = permissionsManager.appState else { return }
                appState.performSetup()
                appState.permissionsWindow?.close()
                appState.appDelegate?.openSettingsWindow()
            } label: {
                Text(continueButtonText)
                    .frame(width: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .disabled(permissionsManager.permissionsState == .missingPermissions)
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private func permissionRow(_ permission: Permission) -> some View {
        HStack(spacing: 16) {
            Image(systemName: permission.hasPermission ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(permission.hasPermission ? .green : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(permission.title)
                    .font(.headline)
                Text(permission.details.first ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !permission.hasPermission {
                Button("Grant") {
                    permission.performRequest()
                    Task {
                        await permission.waitForPermission()
                        permissionsManager.appState?.activate(withPolicy: .regular)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
}
