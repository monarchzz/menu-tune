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
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black

    var id: String { rawValue }

    var weight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

enum AppearanceTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
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

    /// Font weight for the menu bar text.
    @AppStorage("menuBarFontWeight") var menuBarFontWeight: MenuBarFontWeight = .medium

    /// Maximum width for the status item text.
    @AppStorage("maxStatusItemWidth") var maxStatusItemWidth: Double = 300

    /// Enable scrolling text for long labels.
    @AppStorage("scrollingText") var scrollingText: Bool = false

    /// Custom separator between Artist and Title.
    @AppStorage("customSeparator") var customSeparator: String = " - "

    // MARK: - Appearance Settings

    /// Blur intensity for the player window background (0.0 - 1.0).
    @AppStorage("blurIntensity") var blurIntensity: Double = 0.5

    /// Hover tint color as Hex string.
    @AppStorage("hoverTintColorHex") var hoverTintColorHex: String = ""

    /// Theme for the player window foreground (System, Light, Dark).
    @AppStorage("appearanceTheme") var appearanceTheme: AppearanceTheme = .system

    // MARK: - General Settings

    /// Launch the app automatically at login.
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    /// Hide the app icon from the Dock.
    @AppStorage("hideDockIcon") var hideDockIcon: Bool = false
}
