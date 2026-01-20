//
//  PreferencesView.swift
//  MenuTune
//
//  SwiftUI view for the preferences/settings window.
//

import SwiftUI

// MARK: - Preferences View

/// Settings window content for MenuTune preferences.
struct PreferencesView: View {

    @ObservedObject var preferences: PreferencesModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        TabView {
            menuBarTab
                .tabItem {
                    Label("Menu Bar", systemImage: "rectangle.topthird.inset.filled")
                }

            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }

            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 350)
        .padding()
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

            Section("Behavior") {
                Toggle("Hide artist when paused", isOn: $preferences.hideArtistWhenPaused)
                Toggle("Hide title when paused", isOn: $preferences.hideTitleWhenPaused)
                // Toggle("Scroll long text", isOn: $preferences.scrollingText) // TODO: Implement marquee view
            }

            Section("Layout") {
                Picker("Font Weight", selection: $preferences.menuBarFontWeight) {
                    ForEach(MenuBarFontWeight.allCases) { weight in
                        Text(weight.rawValue.capitalized).tag(weight)
                    }
                }

                TextField("Separator", text: $preferences.customSeparator)
                    .frame(width: 100)

                Toggle("Compact View", isOn: $preferences.compactView)

                VStack(alignment: .leading) {
                    Text("Max Width: \(Int(preferences.maxStatusItemWidth))px")
                    Slider(value: $preferences.maxStatusItemWidth, in: 100...600, step: 10)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var appearanceTab: some View {
        Form {
            Section("Player Window") {
                Picker("Theme", selection: $preferences.appearanceTheme) {
                    Text("System").tag(AppearanceTheme.system)
                    Text("Light").tag(AppearanceTheme.light)
                    Text("Dark").tag(AppearanceTheme.dark)
                }

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
                Text("Changes require app restart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            VStack(spacing: 4) {
                Text("MenuTune")
                    .font(.title2)
                    .bold()

                Text(appVersion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("A minimal menu bar music player.")
                .font(.body)
                .multilineTextAlignment(.center)

            Spacer()

            Text("© 2025 MenuTune")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
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
