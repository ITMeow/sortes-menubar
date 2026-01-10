//
//  AboutSettingsPane.swift
//  SortBar
//

import SwiftUI

struct AboutSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openURL) private var openURL

    private var updatesManager: UpdatesManager {
        appState.updatesManager
    }

    private var acknowledgementsURL: URL {
        // swiftlint:disable:next force_unwrapping
        Bundle.main.url(forResource: "Acknowledgements", withExtension: "pdf")!
    }

    private var contributeURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://github.com/jordanbaird/Ice")!
    }

    private var issuesURL: URL {
        contributeURL.appendingPathComponent("issues")
    }

    private var donateURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://icemenubar.app/Donate")!
    }

    private var lastUpdateCheckString: String {
        if let date = updatesManager.lastUpdateCheckDate {
            date.formatted(date: .abbreviated, time: .standard)
        } else {
            "Never"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                VStack(spacing: 16) {
                    if let nsImage = NSImage(named: NSImage.applicationIconName) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 128, height: 128)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    }

                    VStack(spacing: 4) {
                        Text("SortBar")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.primary)
                            .tracking(-1)

                        Text("Version \(Constants.versionString)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 20)

                // Updates Section
                SortBarGroupBox {
                    updatesSectionContent
                }

                // Links Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                    linkButton("Acknowledgements", icon: "doc.text") {
                        NSWorkspace.shared.open(acknowledgementsURL)
                    }
                    linkButton("Contribute", icon: "hammer.fill") {
                        openURL(contributeURL)
                    }
                    linkButton("Report a Bug", icon: "ladybug.fill") {
                        openURL(issuesURL)
                    }
                    linkButton("Support SortBar", icon: "heart.fill", color: .pink) {
                        openURL(donateURL)
                    }
                }
                
                Text(Constants.copyrightString)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 10)
            }
            .padding(40)
        }
    }

    @ViewBuilder
    private var updatesSectionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Updates")
                .font(.headline)
            
            VStack(spacing: 12) {
                Toggle(
                    "Automatically check for updates",
                    isOn: updatesManager.bindings.automaticallyChecksForUpdates
                )
                
                Toggle(
                    "Automatically download updates",
                    isOn: updatesManager.bindings.automaticallyDownloadsUpdates
                )
            }
            
            if updatesManager.canCheckForUpdates {
                Divider()
                HStack {
                    Button("Check Now") {
                        updatesManager.checkForUpdates()
                    }
                    Spacer()
                    Text("Last checked: \(lastUpdateCheckString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func linkButton(_ title: String, icon: String, color: Color = .secondary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // Unused but kept for reference if needed elsewhere
    @ViewBuilder
    private var updatesSection: some View {
        EmptyView()
    }

    @ViewBuilder
    private var bottomBar: some View {
        EmptyView()
    }

    @ViewBuilder
    private var mainForm: some View {
        EmptyView()
    }
}
