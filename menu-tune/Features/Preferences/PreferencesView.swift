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
        Form {
            // Status Bar Display Section
            Section {
                Toggle("Show player icon", isOn: $preferences.showAppIcon)
                Toggle("Show music note when playing", isOn: $preferences.showMusicIcon)
                Toggle("Show artist name", isOn: $preferences.showArtist)
                Toggle("Show track title", isOn: $preferences.showTitle)
            } header: {
                Text("Status Bar Display")
            }
            
            // Width Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum text width: \(Int(preferences.maxStatusItemWidth))px")
                        .font(.body)
                    
                    Slider(
                        value: $preferences.maxStatusItemWidth,
                        in: 100...500,
                        step: 10
                    )
                }
            } header: {
                Text("Size")
            }
            
            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("MenuTune")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 320)
        .fixedSize()
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
