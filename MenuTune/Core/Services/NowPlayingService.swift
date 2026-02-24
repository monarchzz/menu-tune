//
//  NowPlayingService.swift
//  MenuTune
//
//  Centralized now-playing service that owns polling and publishes state.
//

import AppKit
import Combine
import Foundation
import SwiftUI

/// Small typed snapshot of now-playing state. Created on MainActor.
struct NowPlayingState {
    let title: String
    let artist: String
    let album: String?
    let isPlaying: Bool
    let sourceAppBundleID: String?
    let artwork: NSImage?
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
        artwork: NSImage?? = nil,
        totalTime: Double? = nil,
        currentTime: Double? = nil
    ) -> NowPlayingState {
        NowPlayingState(
            title: title ?? self.title,
            artist: artist ?? self.artist,
            album: album ?? self.album,
            isPlaying: isPlaying ?? self.isPlaying,
            sourceAppBundleID: sourceAppBundleID ?? self.sourceAppBundleID,
            artwork: artwork ?? self.artwork,
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
                    artwork: nil, totalTime: 0, currentTime: 0
                )
            case .previous:
                optimistic = current.copy(
                    title: "…", artist: "", album: nil,
                    artwork: nil, totalTime: 0, currentTime: 0
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

    private func refreshNowPlaying() async {
        guard let info = await NowPlayingProvider.fetchNowPlayingInfo() else {
            await MainActor.run { subject.send(nil) }
            return
        }

        let prev = subject.value
        let sameTrack =
            prev.map {
                $0.title == info.title && $0.artist == info.artist && $0.album == info.album
                    && $0.sourceAppBundleID == info.sourceAppBundleID
            } ?? false

        let artwork: NSImage?
        if sameTrack {
            artwork = prev?.artwork
        } else {
            artwork = await fetchArtworkImage(bundleID: info.sourceAppBundleID)
        }

        let state = NowPlayingState(
            title: info.title,
            artist: info.artist,
            album: info.album,
            isPlaying: info.isPlaying,
            sourceAppBundleID: info.sourceAppBundleID,
            artwork: artwork,
            totalTime: info.totalTime,
            currentTime: info.currentTime
        )

        await MainActor.run { subject.send(state) }
    }

    func refresh() async {
        await refreshNowPlaying()
        await refreshArtwork()
    }

    private func refreshArtwork() async {
        guard let current = subject.value else { return }
        let image = await fetchArtworkImage(bundleID: current.sourceAppBundleID)
        await MainActor.run {
            subject.send(current.copy(artwork: image))
        }
    }

    private func fetchArtworkImage(bundleID: String?) async -> NSImage? {
        let playerType = PlayerType.from(bundleID: bundleID)
        let data = await NowPlayingProvider.fetchArtworkData(for: playerType)
        return await MainActor.run { data.flatMap { NSImage(data: $0) } }
    }

}
