//
//  PreferencesModel.swift
//  MenuTune
//
//  Model for storing user preferences with @AppStorage persistence.
//

import Combine
import SwiftUI

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
    
    /// Maximum width for the status item text.
    @AppStorage("maxStatusItemWidth") var maxStatusItemWidth: Double = 300
}
