//
//  PreferencesView.swift
//  MenuTune
//
//  SwiftUI view for the preferences/settings window.
//

import SwiftUI

// MARK: - Preferences Tab Enum

enum PreferencesTab: String, CaseIterable, Identifiable {
    case menuBar = "Menu Bar"
    case appearance = "Appearance"
    case general = "General"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .menuBar: return "rectangle.topthird.inset.filled"
        case .appearance: return "paintpalette"
        case .general: return "gear"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Preferences View

/// Settings window content for MenuTune preferences.
struct PreferencesView: View {

    @ObservedObject var preferences: PreferencesModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: PreferencesTab = .menuBar

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            List(PreferencesTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            Group {
                switch selectedTab {
                case .menuBar:
                    menuBarTab
                case .appearance:
                    appearanceTab
                case .general:
                    generalTab
                case .about:
                    aboutTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 600, height: 450)
    }

    // MARK: - Tabs

    private var menuBarTab: some View {
        Form {
            Section("Visibility") {
                Toggle("Show artist", isOn: $preferences.showArtist)
                Toggle("Show title", isOn: $preferences.showTitle)
                Toggle("Show player icon", isOn: $preferences.showAppIcon)
                Toggle("Show music note when playing", isOn: $preferences.showMusicIcon)
            }

            Section("When Paused") {
                Toggle("Hide artist when paused", isOn: $preferences.hideArtistWhenPaused)
                Toggle("Hide title when paused", isOn: $preferences.hideTitleWhenPaused)
            }

            Section("Layout") {
                Toggle("Compact View", isOn: $preferences.compactView)

                if preferences.compactView {
                    Picker("Font Weight (Top)", selection: $preferences.fontWeightCompactTop) {
                        ForEach(MenuBarFontWeight.allCases) { weight in
                            Text(weight.rawValue.capitalized).tag(weight)
                        }
                    }

                    Picker("Font Weight (Bottom)", selection: $preferences.fontWeightCompactBottom)
                    {
                        ForEach(MenuBarFontWeight.allCases) { weight in
                            Text(weight.rawValue.capitalized).tag(weight)
                        }
                    }
                } else {
                    Picker("Font Weight", selection: $preferences.fontWeightNormal) {
                        ForEach(MenuBarFontWeight.allCases) { weight in
                            Text(weight.rawValue.capitalized).tag(weight)
                        }
                    }

                    Picker("Separator", selection: $preferences.customSeparator) {
                        Text(" - ").tag(" - ")
                        Text(" · ").tag(" · ")
                        Text(" | ").tag(" | ")
                        Text(" / ").tag(" / ")
                        Text("  ").tag("  ")
                    }
                }

                VStack(alignment: .leading) {
                    Text("Max Width: \(Int(preferences.maxStatusItemWidth))px")
                    Slider(value: $preferences.maxStatusItemWidth, in: 50...500, step: 50)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var appearanceTab: some View {
        Form {
            Section("Player Window") {
                VStack(alignment: .leading) {
                    Text("Blur Intensity")
                    Slider(value: $preferences.blurIntensity, in: 0...1)
                }

                ColorPicker(
                    "Tint Color",
                    selection: Binding(
                        get: { Color(hex: preferences.hoverTintColorHex) ?? .clear },
                        set: { preferences.hoverTintColorHex = $0.toHex() ?? "" }
                    ))

                VStack(alignment: .leading) {
                    Text("Tint Opacity")
                    Slider(value: $preferences.hoverTintOpacity, in: 0...1)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $preferences.launchAtLogin)
            }

            Section("Dock") {
                Toggle("Hide Dock Icon", isOn: $preferences.hideDockIcon)
            }

            Section("Refresh") {
                VStack(alignment: .leading) {
                    Text("Polling Interval: \(Int(preferences.pollIntervalSeconds))s")
                    Slider(value: $preferences.pollIntervalSeconds, in: 1...10, step: 1)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var aboutTab: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                VStack(spacing: 8) {
                    Text("Menu Tune")
                        .font(.system(size: 28, weight: .bold))

                    Text(appVersion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Show Now Playing music in your menu bar.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Text("© 2026 Menu Tune")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview

#Preview {
    PreferencesView(preferences: PreferencesModel())
}
