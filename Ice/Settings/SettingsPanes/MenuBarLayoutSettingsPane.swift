//
//  MenuBarLayoutSettingsPane.swift
//  Ice
//

import SwiftUI

struct MenuBarLayoutSettingsPane: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if !ScreenCapture.cachedCheckPermissions() {
            missingScreenRecordingPermission
        } else if appState.menuBarManager.isMenuBarHiddenBySystemUserDefaults {
            cannotArrange
        } else {
            IceForm(alignment: .leading, spacing: 20) {
                header
                layoutBars
            }
            .onAppear {
                // Force refresh item cache and image cache when this view appears
                Task {
                    Logger.layoutPane.info("MenuBarLayoutSettingsPane appeared, forcing cache refresh")

                    // Force refresh items
                    await appState.itemManager.forceCacheItems()

                    // Log item cache status
                    let visibleItems = appState.itemManager.itemCache[.visible]
                    let hiddenItems = appState.itemManager.itemCache[.hidden]
                    let alwaysHiddenItems = appState.itemManager.itemCache[.alwaysHidden]
                    Logger.layoutPane.info("Item cache - visible: \(visibleItems.count), hidden: \(hiddenItems.count), alwaysHidden: \(alwaysHiddenItems.count)")

                    // Force refresh images
                    if ScreenCapture.cachedCheckPermissions(reset: true) {
                        Logger.layoutPane.info("Screen capture permission granted, updating image cache")
                        await appState.imageCache.updateCacheWithoutChecks(sections: MenuBarSection.Name.allCases)
                        Logger.layoutPane.info("Image cache updated, images count: \(appState.imageCache.images.count)")
                    } else {
                        Logger.layoutPane.warning("Screen capture permission NOT granted")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        Text("Drag to arrange your menu bar items")
            .font(.title2)

        IceGroupBox {
            AnnotationView(
                alignment: .center,
                font: .callout.bold()
            ) {
                Label {
                    Text("Tip: you can also arrange menu bar items by Command + dragging them in the menu bar")
                } icon: {
                    Image(systemName: "lightbulb")
                }
            }
        }
    }

    @ViewBuilder
    private var layoutBars: some View {
        VStack(spacing: 25) {
            ForEach(MenuBarSection.Name.allCases, id: \.self) { section in
                layoutBar(for: section)
            }
        }
    }

    @ViewBuilder
    private var cannotArrange: some View {
        Text("Ice cannot arrange menu bar items in automatically hidden menu bars")
            .font(.title3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var missingScreenRecordingPermission: some View {
        VStack {
            Text("Menu bar layout requires screen recording permissions")
                .font(.title2)

            Button {
                appState.navigationState.settingsNavigationIdentifier = .advanced
            } label: {
                Text("Go to Advanced Settings")
            }
            .buttonStyle(.link)
        }
    }

    @ViewBuilder
    private func layoutBar(for section: MenuBarSection.Name) -> some View {
        if
            let section = appState.menuBarManager.section(withName: section),
            section.isEnabled
        {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(section.name.displayString) Section")
                    .font(.system(size: 14))
                    .padding(.leading, 2)

                LayoutBar(section: section)
                    .environmentObject(appState.imageCache)
            }
        }
    }
}

// MARK: - Logger

private extension Logger {
    static let layoutPane = Logger(category: "MenuBarLayoutSettingsPane")
}
