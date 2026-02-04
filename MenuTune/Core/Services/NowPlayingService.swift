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

    /// Returns a copy with specified fields overridden.
    func copy(
        title: String? = nil,
        artist: String? = nil,
        album: String?? = nil,
        isPlaying: Bool? = nil,
        sourceAppBundleID: String?? = nil,
        artworkID: String?? = nil,
        totalTime: Double? = nil,
        currentTime: Double? = nil
    ) -> NowPlayingState {
        NowPlayingState(
            title: title ?? self.title,
            artist: artist ?? self.artist,
            album: album ?? self.album,
            isPlaying: isPlaying ?? self.isPlaying,
            sourceAppBundleID: sourceAppBundleID ?? self.sourceAppBundleID,
            artworkID: artworkID ?? self.artworkID,
            totalTime: totalTime ?? self.totalTime,
            currentTime: currentTime ?? self.currentTime
        )
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
    private var artworkFetchAttempts: Int = 0

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
            let optimistic: NowPlayingState
            switch action {
            case .togglePlayPause:
                optimistic = current.copy(isPlaying: !current.isPlaying)
            case .next:
                optimistic = current.copy(
                    title: "…", artist: "", album: nil,
                    artworkID: nil, totalTime: 0, currentTime: 0
                )
            case .previous:
                optimistic = current.copy(
                    title: "…", artist: "", album: nil,
                    artworkID: nil, totalTime: 0, currentTime: 0
                )
            case .seek(let seconds):
                optimistic = current.copy(currentTime: seconds)
            }
            subject.send(optimistic)
        }

        Task { [weak self] in
            guard let self else { return }
            self.stop()
            try? await Task.sleep(for: .milliseconds(500))
            self.start()
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
        var shouldFetchArtwork = true
        let prev = subject.value
        let sameTrack =
            prev.map {
                $0.title == info.title && $0.artist == info.artist && $0.album == info.album
                    && $0.sourceAppBundleID == info.sourceAppBundleID
            } ?? false

        if sameTrack, let prev {
            // Re-fetch if previous artwork was nil and we haven't exhausted attempts (max 2)
            shouldFetchArtwork = prev.artworkID == nil && artworkFetchAttempts < 2
            artworkID = prev.artworkID
        } else {
            // New track or first run: reset attempts counter
            artworkFetchAttempts = 0
        }

        // Only fetch artwork for Spotify and Apple Music
        let playerType = PlayerType.from(bundleID: info.sourceAppBundleID)

        if shouldFetchArtwork {
            artworkFetchAttempts += 1
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
