//
//  PreferencesModel.swift
//  MenuTune
//
//  Model for storing user preferences with @AppStorage persistence.
//

import Combine
import SwiftUI

// MARK: - Enums

enum MenuBarFontWeight: String, CaseIterable, Identifiable {
    case light, regular, medium, semibold, bold

    var id: String { rawValue }

    var weight: Font.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

// MARK: - Preferences Model

/// Observable model for user preferences, backed by UserDefaults.
@MainActor
final class PreferencesModel: ObservableObject {

    // MARK: - Status Bar Display Settings

    /// Show the player app icon in the status bar.
    @AppStorage("showAppIcon") var showAppIcon: Bool = true

    /// Show a music note (♫) when playing.
    @AppStorage("showMusicIcon") var showMusicIcon: Bool = true

    /// Show the artist name in the status bar.
    @AppStorage("showArtist") var showArtist: Bool = true

    /// Show the track title in the status bar.
    @AppStorage("showTitle") var showTitle: Bool = true

    /// Hide the artist name when playback is paused.
    @AppStorage("hideArtistWhenPaused") var hideArtistWhenPaused: Bool = false

    /// Hide the track title when playback is paused.
    @AppStorage("hideTitleWhenPaused") var hideTitleWhenPaused: Bool = false

    /// Use a compact view (smaller padding/layout).
    @AppStorage("compactView") var compactView: Bool = false

    /// Font weight for the menu bar text (Normal Mode).
    @AppStorage("fontWeightNormal") var fontWeightNormal: MenuBarFontWeight = .medium

    /// Font weight for the top line (Artist) in compact view.
    @AppStorage("fontWeightCompactTop") var fontWeightCompactTop: MenuBarFontWeight = .medium

    /// Font weight for the bottom line (Title) in compact view.
    @AppStorage("fontWeightCompactBottom") var fontWeightCompactBottom: MenuBarFontWeight = .medium

    /// Maximum width for the status item text.
    @AppStorage("maxStatusItemWidth") var maxStatusItemWidth: Double = 300

    /// Custom separator between Artist and Title.
    @AppStorage("customSeparator") var customSeparator: String = " - "

    // MARK: - Appearance Settings

    /// Blur intensity for the player window background (0.0 - 1.0).
    @AppStorage("blurIntensity") var blurIntensity: Double = 0.5

    /// Hover tint color as Hex string.
    @AppStorage("hoverTintColorHex") var hoverTintColorHex: String = ""

    /// Opacity for the tint color (0.0 - 1.0).
    @AppStorage("hoverTintOpacity") var hoverTintOpacity: Double = 0.3

    // MARK: - General Settings

    /// Launch the app automatically at login.
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    /// Hide the app icon from the Dock.
    @AppStorage("hideDockIcon") var hideDockIcon: Bool = true

    /// Polling interval in seconds for refreshing now-playing info.
    @AppStorage("pollIntervalSeconds") var pollIntervalSeconds: Double = 2.0
}
