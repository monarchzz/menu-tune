//
//  PlaybackModel.swift
//  MenuTune
//
//  Main model managing playback state with auto-detection and polling.
//  Uses NowPlayingProvider for universal source detection, AppleScript for controls.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Playback Model

/// Main model managing playback state, auto-detection, and polling.
/// Uses NowPlayingProvider to detect ANY playing source (including browsers),
/// but only provides playback controls for Spotify and Apple Music.
@Observable
@MainActor
final class PlaybackModel {

    // MARK: - Observable Properties

    var imageURL: URL?
    var image: NSImage?
    var isPlaying: Bool = false
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var totalTime: Double = 1
    var currentTime: Double = 0
    var playerType: PlayerType = .none
    var sourceAppBundleID: String?

    // MARK: - Properties

    private var controller: (any MusicPlayerController)?
    private var cancellables = Set<AnyCancellable>()
    private var currentArtworkID: String?

    /// Returns true if the current source supports playback controls.
    var supportsControl: Bool {
        playerType.supportsControl
    }

    /// Icon name for the current player type.
    var playerIconName: String {
        playerType.iconName
    }

    // MARK: - Initialization

    init() {
        // Subscribe to `NowPlayingService` via Combine (deliver on main runloop)
        NowPlayingService.shared.publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                Task { @MainActor in
                    self?.applyState(state)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Fetches current playback info on demand.
    func fetchInfo() async {
        await NowPlayingService.shared.refreshNowPlaying()
    }

    /// Toggles between play and pause (only for controllable sources).
    func togglePlayPause() {
        guard supportsControl else {
            Log.debug("Playback control not supported for \(playerType)", category: .playback)
            return
        }

        // Let the player-specific controller execute the command
        controller?.togglePlayPause()

        // Publish optimistic state and schedule authoritative refresh
        Task { await NowPlayingService.shared.perform(.togglePlayPause) }
    }

    /// Skips to the next track (only for controllable sources).
    func skipForward() {
        guard supportsControl else { return }

        controller?.skipForward()
        Task { await NowPlayingService.shared.perform(.next) }
    }

    /// Skips to the previous track (only for controllable sources).
    func skipBack() {
        guard supportsControl else { return }

        controller?.skipBack()
        Task { await NowPlayingService.shared.perform(.previous) }
    }

    /// Updates the playback position (only for controllable sources).
    func updatePlaybackPosition(to seconds: Double) {
        guard supportsControl else { return }

        controller?.updatePlaybackPosition(to: seconds)
        currentTime = seconds
        Task { await NowPlayingService.shared.perform(.seek(seconds: seconds)) }
    }

    /// Opens the current music app.
    func openMusicApp() {
        if let bundleID = sourceAppBundleID,
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        {
            NSWorkspace.shared.openApplication(
                at: url, configuration: NSWorkspace.OpenConfiguration())
        } else {
            controller?.openApp()
        }
    }

    // MARK: - Private Methods

    // Apply NowPlayingState emitted by NowPlayingService
    private func applyState(_ state: NowPlayingState) {
        title = state.title
        artist = state.artist
        album = state.album ?? ""
        isPlaying = state.isPlaying
        sourceAppBundleID = state.sourceAppBundleID
        totalTime = state.totalTime > 0 ? state.totalTime : 1
        currentTime = state.currentTime

        // Load artwork from cache if artworkID changed
        if state.artworkID != currentArtworkID {
            currentArtworkID = state.artworkID
            Task { @MainActor in
                if let artID = state.artworkID {
                    let img = await ArtworkCache.shared.image(for: artID)
                    self.image = img
                } else {
                    self.image = nil
                }
            }
        }

        let newPlayerType = PlayerType.from(bundleID: state.sourceAppBundleID)
        if newPlayerType.supportsControl {
            setupControllerForType(newPlayerType)
        } else {
            controller = nil
            playerType = newPlayerType
        }
    }

    /// Sets up the appropriate controller for a player type.
    private func setupControllerForType(_ type: PlayerType) {
        guard playerType != type else { return }

        switch type {
        case .spotify:
            controller = SpotifyController()
            playerType = .spotify
            Log.debug("Controller switched to Spotify", category: .playback)
        case .appleMusic:
            controller = AppleMusicController()
            playerType = .appleMusic
            Log.debug("Controller switched to Apple Music", category: .playback)
        default:
            controller = nil
            playerType = type
            Log.debug("Controller set to None (generic source)", category: .playback)
        }
    }

    private func reset() {
        title = ""
        artist = ""
        album = ""
        isPlaying = false
        imageURL = nil
        image = nil
        currentTime = 0
        totalTime = 1
        sourceAppBundleID = nil
        playerType = .none
        controller = nil
    }
}
