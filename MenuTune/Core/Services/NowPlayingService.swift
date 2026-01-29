//
//  NowPlayingService.swift
//  MenuTune
//
//  Centralized now-playing service that owns polling and publishes state.
//

import AppKit
import Combine
import CryptoKit
import Foundation
import SwiftUI

/// Small typed snapshot of now-playing state. Created on MainActor.
struct NowPlayingState {
    let title: String
    let artist: String
    let album: String?
    let isPlaying: Bool
    let sourceAppBundleID: String?
    let artworkID: String?
    let totalTime: Double
    let currentTime: Double

    var playerIconName: String {
        PlayerType.from(bundleID: sourceAppBundleID).iconName
    }
}

/// Playback actions supported by the service.
enum PlaybackAction {
    case togglePlayPause
    case next
    case previous
    case seek(seconds: Double)
}

@MainActor
final class NowPlayingService {
    static let shared = NowPlayingService()
    private init() {}

    // CurrentValueSubject holds optional state so new subscribers can start with nil
    private let subject = CurrentValueSubject<NowPlayingState?, Never>(nil)

    // Public Combine publisher that emits non-nil states
    var publisher: AnyPublisher<NowPlayingState, Never> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private var pollTask: Task<Void, Never>?
    private var pollIntervalSeconds: TimeInterval = 2

    var isRunning: Bool { pollTask != nil }

    // MARK: - Configuration

    /// Updates the polling interval. Takes effect on the next poll cycle.
    func setPollInterval(_ seconds: TimeInterval) {
        pollIntervalSeconds = max(1, seconds)
    }

    // MARK: - Start / Stop

    func start() {
        guard pollTask == nil else { return }

        // Use polling mode (CLI invocation)
        Log.info("Starting NowPlayingService in polling mode", category: .playback)
        startPollingMode()
    }

    /// Start polling mode.
    private func startPollingMode() {
        // Immediate refresh then periodic polling
        pollTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshNowPlaying()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.pollIntervalSeconds))
                if Task.isCancelled { break }
                await self.refreshNowPlaying()
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Public API

    /// Performs a playback action with optimistic publish + background refresh.
    func perform(_ action: PlaybackAction) async {
        // Build and publish optimistic state if available
        if let current = subject.value {
            var optimistic = current
            switch action {
            case .togglePlayPause:
                optimistic = NowPlayingState(
                    title: current.title,
                    artist: current.artist,
                    album: current.album,
                    isPlaying: !current.isPlaying,
                    sourceAppBundleID: current.sourceAppBundleID,
                    artworkID: current.artworkID,
                    totalTime: current.totalTime,
                    currentTime: current.currentTime
                )
            case .next:
                // Clear title/artist briefly to indicate change
                optimistic = NowPlayingState(
                    title: "…", artist: "", album: nil, isPlaying: current.isPlaying,
                    sourceAppBundleID: current.sourceAppBundleID, artworkID: nil,
                    totalTime: 0, currentTime: 0)
            case .previous:
                optimistic = NowPlayingState(
                    title: "…", artist: "", album: nil, isPlaying: current.isPlaying,
                    sourceAppBundleID: current.sourceAppBundleID, artworkID: nil,
                    totalTime: 0, currentTime: 0)
            case .seek(_):
                // We don't change metadata for seek; no optimistic change for now
                optimistic = current
            }
            subject.send(optimistic)
        }

        // NOTE: NowPlayingService is player-agnostic and must NOT execute player-specific
        // AppleScript commands. Controllers (e.g., SpotifyController, AppleMusicController)
        // are responsible for executing playback commands. The service only publishes an
        // optimistic state and schedules an authoritative refresh.

        // Trigger a near-immediate authoritative refresh in background
        Task.detached(priority: .userInitiated) { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            await self?.refreshNowPlaying()
        }
    }

    // MARK: - Refresh

    /// Fetches authoritative now-playing info and publishes it.
    func refreshNowPlaying() async {
        // Fetch core info
        guard let info = await NowPlayingProvider.fetchNowPlayingInfo() else {
            await MainActor.run { subject.send(nil) }
            return
        }

        // Decide whether to fetch artwork: compare incoming metadata with last authoritative state
        var artworkID: String? = nil
        let shouldFetchArtwork: Bool
        if let prev = subject.value {
            let sameTitle = prev.title == info.title
            let sameArtist = prev.artist == info.artist
            let sameAlbum = prev.album == info.album
            let sameSource = prev.sourceAppBundleID == info.sourceAppBundleID
            if sameTitle && sameArtist && sameAlbum && sameSource, let prevArtwork = prev.artworkID
            {
                shouldFetchArtwork = false
                artworkID = prevArtwork
            } else {
                shouldFetchArtwork = true
            }
        } else {
            shouldFetchArtwork = true
        }

        // Only fetch artwork for Spotify and Apple Music
        let playerType = PlayerType.from(bundleID: info.sourceAppBundleID)
        let supportsArtwork = playerType == .spotify || playerType == .appleMusic

        if shouldFetchArtwork && supportsArtwork {
            // Fetch artwork (NowPlayingProvider.fetchArtwork ensures NSImage created on MainActor)
            let artworkData = await NowPlayingProvider.fetchArtworkData(for: playerType)
            if let data = artworkData {
                // Use a deterministic artwork ID derived from metadata (title|artist|album|source)
                let key = Self.artworkKey(from: info)
                artworkID = key
                Task.detached {
                    try? await ArtworkCache.shared.save(data: data, for: key)
                }
            }
        }

        let state = NowPlayingState(
            title: info.title,
            artist: info.artist,
            album: info.album,
            isPlaying: info.isPlaying,
            sourceAppBundleID: info.sourceAppBundleID,
            artworkID: artworkID,
            totalTime: info.totalTime,
            currentTime: info.currentTime
        )

        await MainActor.run { subject.send(state) }
    }

    private static func artworkKey(from info: NowPlayingInfo) -> String {
        let components = [info.title, info.artist, info.album ?? "", info.sourceAppBundleID ?? ""]
            .joined(separator: "|")
        let digest = SHA256.hash(data: Data(components.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
