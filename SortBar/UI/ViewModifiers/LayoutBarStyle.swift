//
//  LayoutBarStyle.swift
//  SortBar
//

import SwiftUI

extension View {
    /// Returns a view that is drawn in the style of a layout bar.
    ///
    /// - Note: The view this modifier is applied to must be transparent, or the style
    ///   will be drawn incorrectly.
    @ViewBuilder
    func layoutBarStyle(appState: AppState, averageColorInfo: MenuBarAverageColorInfo?) -> some View {
        background {
            if appState.isActiveSpaceFullscreen {
                Color.black
            } else if let averageColorInfo {
                // Check if the color is too bright - if so, use a darker background
                // to ensure menu bar icons (which are typically light-colored) are visible
                // Use 1.0 as default so if brightness calculation fails, we assume it's bright
                let brightness = averageColorInfo.color.brightness ?? 1.0
                if brightness >= 0.4 {
                    // Background is too bright, use a dark gray instead
                    Color(red: 0.18, green: 0.18, blue: 0.18)
                        .overlay(
                            Material.bar
                                .opacity(0.1)
                                .blendMode(.softLight)
                        )
                } else {
                    switch averageColorInfo.source {
                    case .menuBarWindow:
                        Color(cgColor: averageColorInfo.color)
                            .overlay(
                                Material.bar
                                    .opacity(0.2)
                                    .blendMode(.softLight)
                            )
                    case .desktopWallpaper:
                        Color(cgColor: averageColorInfo.color)
                            .overlay(
                                Material.bar
                                    .opacity(0.5)
                                    .blendMode(.softLight)
                            )
                    }
                }
            } else {
                // Fallback to a dark gray that works well for menu bar icons
                Color(red: 0.18, green: 0.18, blue: 0.18)
            }
        }
        .overlay {
            if !appState.isActiveSpaceFullscreen {
                switch appState.appearanceManager.configuration.current.tintKind {
                case .none:
                    EmptyView()
                case .solid:
                    Color(cgColor: appState.appearanceManager.configuration.current.tintColor)
                        .opacity(0.2)
                        .allowsHitTesting(false)
                case .gradient:
                    appState.appearanceManager.configuration.current.tintGradient
                        .opacity(0.2)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}
