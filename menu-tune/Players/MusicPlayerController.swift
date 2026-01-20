//
//  MusicPlayerController.swift
//  MenuTune
//
//  Protocol defining the interface for music player controllers.
//

import Foundation

// MARK: - Music Player Controller Protocol

/// Protocol defining the interface for music player controllers.
/// Implemented by AppleMusicController and SpotifyController.
@MainActor
protocol MusicPlayerController: Sendable {
    
    /// Toggles between play and pause states.
    func togglePlayPause()
    
    /// Skips to the next track.
    func skipForward()
    
    /// Skips to the previous track.
    func skipBack()
    
    /// Updates the playback position.
    /// - Parameter seconds: The position to seek to in seconds.
    func updatePlaybackPosition(to seconds: Double)
    
    /// Opens the music app.
    func openApp()
}
