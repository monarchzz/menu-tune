//
//  NowPlayingProvider.swift
//  MenuTune
//
//  Provider for system-wide Now Playing info.
//

import AppKit
import Foundation

// MARK: - Now Playing Provider

/// Provider for fetching system-wide now playing info.
/// Uses ScriptService to fetch info from Spotify and Apple Music.
final class NowPlayingProvider {
    private init() {}

    // MARK: - Public Methods

    /// Fetches now playing info from the system.
    /// First fetches bundle ID, then routes to appropriate method.
    /// - Returns: NowPlayingInfo if media is playing, nil otherwise.
    static func fetchNowPlayingInfo() async -> NowPlayingInfo? {
        // First, get the bundle ID of the currently playing app
        guard let bundleID = await ScriptService.shared.fetchNowPlayingBundleID() else {
            return nil
        }

        Log.debug(
            "NowPlayingProvider: detected playing app bundle ID: \(bundleID)", category: .services)

        // Route to appropriate fetch method based on bundle ID
        switch bundleID {
        case ScriptService.spotifyBundleID:
            return await ScriptService.shared.fetchSpotifyInfo()
        case ScriptService.appleMusicBundleID:
            return await ScriptService.shared.fetchAppleMusicInfo()
        default:
            // Generic source (browser, other apps) - use MediaRemote
            return await ScriptService.shared.fetchGenericNowPlayingInfo()
        }
    }

    /// Fetches artwork for the currently playing media as raw Data.
    /// Only supports Spotify and Apple Music.
    /// - Parameter playerType: The player type to fetch artwork from.
    /// - Returns: Data if artwork is available, nil otherwise.
    static func fetchArtworkData(for playerType: PlayerType) async -> Data? {
        Log.debug("NowPlayingProvider: fetching artwork for \(playerType)", category: .services)
        switch playerType {
        case .spotify:
            return await ScriptService.shared.fetchSpotifyArtwork()
        case .appleMusic:
            // Apple Music returns NSImage, convert to Data
            if let image = await ScriptService.shared.fetchAppleMusicArtwork() {
                return image.tiffRepresentation
            }
            return nil
        default:
            return nil
        }
    }
}
