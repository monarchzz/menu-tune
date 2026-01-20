//
//  PlayerType.swift
//  MenuTune
//
//  Defines the types of music players and their capabilities.
//

import Foundation

// MARK: - Known Browser Bundle IDs

/// List of known browser bundle identifiers for music playback detection.
enum KnownBrowsers {
    static let bundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "company.thebrowser.Browser",   // Arc
        "com.brave.Browser",
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi",
        "app.zen-browser.zen",          // Zen Browser
    ]
    
    /// Checks if a bundle ID belongs to a known browser.
    static func isBrowser(_ bundleID: String) -> Bool {
        bundleIDs.contains(bundleID)
    }
}

// MARK: - Player Type

/// Represents the type of music player currently active.
enum PlayerType: Sendable, Equatable {
    case spotify
    case appleMusic
    case browser(bundleID: String)  // Chrome, Safari, Arc, Zen, etc.
    case generic(bundleID: String)  // Any other app
    case none
    
    // MARK: - Capabilities
    
    /// Returns true if this player type supports playback controls.
    var supportsControl: Bool {
        switch self {
        case .spotify, .appleMusic:
            return true
        case .browser, .generic, .none:
            return false
        }
    }
    
    // MARK: - Icon
    
    /// Returns the icon name for this player type.
    /// For Spotify/Apple Music, returns the asset name.
    /// For other sources, returns an SF Symbol name (prefixed with "sf.").
    var iconName: String {
        switch self {
        case .spotify:
            return "SpotifyIcon"
        case .appleMusic:
            return "AppleMusicIcon"
        case .browser, .generic, .none:
            return "sf.music.note"  // SF Symbol prefix
        }
    }
    
    /// Returns true if iconName refers to an SF Symbol (prefixed with "sf.").
    var isSystemIcon: Bool {
        iconName.hasPrefix("sf.")
    }
    
    /// Returns the SF Symbol name (without prefix) if this is a system icon.
    var systemIconName: String? {
        guard isSystemIcon else { return nil }
        return String(iconName.dropFirst(3))
    }
    
    // MARK: - Factory
    
    /// Creates a PlayerType from a bundle identifier.
    static func from(bundleID: String?) -> PlayerType {
        guard let bundleID = bundleID, !bundleID.isEmpty else {
            return .none
        }
        
        switch bundleID {
        case "com.spotify.client":
            return .spotify
        case "com.apple.Music":
            return .appleMusic
        case let id where KnownBrowsers.isBrowser(id):
            return .browser(bundleID: id)
        default:
            return .generic(bundleID: bundleID)
        }
    }
}
