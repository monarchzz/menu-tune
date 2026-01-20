//
//  AppleMusicController.swift
//  MenuTune
//
//  Controller for Apple Music playback commands.
//

import AppKit
import Foundation

// MARK: - Apple Music Controller

/// Controller for Apple Music playback commands.
/// Uses ScriptService for playback control.
@MainActor
final class AppleMusicController: MusicPlayerController, @unchecked Sendable {

    // MARK: - Properties

    static let bundleIdentifier = ScriptService.appleMusicBundleID

    // MARK: - MusicPlayerController

    func togglePlayPause() {
        Log.debug("Apple Music: togglePlayPause", category: .appleMusic)
        ScriptService.shared.executeAppleMusic(.playPause)
    }

    func skipForward() {
        Log.debug("Apple Music: skipForward", category: .appleMusic)
        ScriptService.shared.executeAppleMusic(.nextTrack)
    }

    func skipBack() {
        Log.debug("Apple Music: skipBack", category: .appleMusic)
        ScriptService.shared.executeAppleMusic(.previousTrack)
    }

    func updatePlaybackPosition(to seconds: Double) {
        Log.debug("Apple Music: seek to \(Int(seconds))s", category: .appleMusic)
        ScriptService.shared.executeAppleMusic(.seek(seconds: seconds))
    }

    func openApp() {
        ScriptService.shared.openApp(bundleID: Self.bundleIdentifier)
    }
}
