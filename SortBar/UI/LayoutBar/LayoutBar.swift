//
//  LayoutBar.swift
//  SortBar
//

import SwiftUI

struct LayoutBar: View {
    private struct Representable: NSViewRepresentable {
        let appState: AppState
        let section: MenuBarSection
        let spacing: CGFloat

        func makeNSView(context: Context) -> LayoutBarScrollView {
            LayoutBarScrollView(appState: appState, section: section, spacing: spacing)
        }

        func updateNSView(_ nsView: LayoutBarScrollView, context: Context) {
            nsView.spacing = spacing
        }
    }

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var imageCache: MenuBarItemImageCache

    let section: MenuBarSection
    let spacing: CGFloat

    private var menuBarManager: MenuBarManager {
        appState.menuBarManager
    }

    private var backgroundShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    /// Dark background color for the layout bar
    private var backgroundColor: Color {
        // Semi-transparent dock-like appearance
        Color.black.opacity(0.75)
    }

    init(section: MenuBarSection, spacing: CGFloat = 0) {
        self.section = section
        self.spacing = spacing
    }

    var body: some View {
        ZStack {
            // Background layer
            backgroundColor
                .background(.ultraThinMaterial)

            // Content layer
            conditionalBody
        }
        .frame(height: 52) // Slightly taller for better touch target
        .frame(maxWidth: .infinity)
        .clipShape(backgroundShape)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5) // Deep shadow
        .overlay {
            backgroundShape
                .inset(by: 0.5)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var conditionalBody: some View {
        if imageCache.cacheFailed(for: section.name) {
            Text("Unable to display menu bar items")
                .foregroundStyle(.white)
        } else {
            Representable(appState: appState, section: section, spacing: spacing)
        }
    }
}
