//
//  SpotifyController.swift
//  MenuTune
//
//  Controller for Spotify playback commands.
//

import AppKit
import Foundation

// MARK: - Spotify Controller

/// Controller for Spotify playback commands.
/// Uses ScriptService for playback control.
@MainActor
final class SpotifyController: MusicPlayerController, @unchecked Sendable {

    // MARK: - Properties

    static let bundleIdentifier = ScriptService.spotifyBundleID

    // MARK: - MusicPlayerController

    func togglePlayPause() {
        Log.debug("Spotify: togglePlayPause", category: .spotify)
        ScriptService.shared.executeSpotify(.playPause)
    }

    func skipForward() {
        Log.debug("Spotify: skipForward", category: .spotify)
        ScriptService.shared.executeSpotify(.nextTrack)
    }

    func skipBack() {
        Log.debug("Spotify: skipBack", category: .spotify)
        ScriptService.shared.executeSpotify(.previousTrack)
    }

    func updatePlaybackPosition(to seconds: Double) {
        Log.debug("Spotify: seek to \(Int(seconds))s", category: .spotify)
        ScriptService.shared.executeSpotify(.seek(seconds: seconds))
    }

    func openApp() {
        ScriptService.shared.openApp(bundleID: Self.bundleIdentifier)
    }
}
