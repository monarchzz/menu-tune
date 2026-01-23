//
//  ScriptService.swift
//  MenuTune
//
//  Abstraction layer for AppleScript operations.
//  Provides type-safe methods for Spotify and Apple Music control.
//

import AppKit
import Foundation

// MARK: - Enums

/// Actions for Spotify playback control.
enum SpotifyAction {
    case playPause
    case nextTrack
    case previousTrack
    case seek(seconds: Double)
}

/// Actions for Apple Music playback control.
enum AppleMusicAction {
    case playPause
    case nextTrack
    case previousTrack
    case seek(seconds: Double)
}

// MARK: - Script Service

/// Abstraction layer for all AppleScript operations.
/// Controllers and providers should use this service instead of calling AppleScriptRunner directly.
final class ScriptService {

    // MARK: - Singleton

    static let shared = ScriptService()
    private init() {}

    // MARK: - Bundle Identifiers

    static let spotifyBundleID = "com.spotify.client"
    static let appleMusicBundleID = "com.apple.Music"

    // MARK: - Spotify Commands

    /// Execute a Spotify playback command.
    func executeSpotify(_ action: SpotifyAction) {
        let script: String
        switch action {
        case .playPause:
            script = "tell application \"Spotify\" to playpause"
        case .nextTrack:
            script = "tell application \"Spotify\" to next track"
        case .previousTrack:
            script = "tell application \"Spotify\" to previous track"
        case .seek(let seconds):
            script = "tell application \"Spotify\" to set player position to \(seconds)"
        }

        Task.detached {
            _ = await AppleScriptRunner.runAppleScript(script)
        }
    }

    // MARK: - Apple Music Commands

    /// Execute an Apple Music playback command.
    func executeAppleMusic(_ action: AppleMusicAction) {
        let script: String
        switch action {
        case .playPause:
            script = "tell application \"Music\" to playpause"
        case .nextTrack:
            script = "tell application \"Music\" to next track"
        case .previousTrack:
            script = "tell application \"Music\" to previous track"
        case .seek(let seconds):
            script = "tell application \"Music\" to set player position to \(seconds)"
        }

        Task.detached {
            _ = await AppleScriptRunner.runAppleScript(script)
        }
    }

    // MARK: - Now Playing Info

    /// Fetches the bundle ID of the currently playing app via MediaRemote.
    /// - Returns: Bundle ID string if available, nil otherwise.
    func fetchNowPlayingBundleID() async -> String? {
        let script = """
            use framework "Foundation"
            use framework "AppKit"
            use scripting additions

            on run
                set MediaRemotePath to "/System/Library/PrivateFrameworks/MediaRemote.framework"
                set MediaRemoteBundle to current application's NSBundle's bundleWithPath:MediaRemotePath
                MediaRemoteBundle's load()
                
                set MRNowPlayingRequestClass to current application's NSClassFromString("MRNowPlayingRequest")
                
                set playerPath to MRNowPlayingRequestClass's localNowPlayingPlayerPath()
                if playerPath is missing value then return ""
                set clientInfo to playerPath's client()
                if clientInfo is missing value then return ""
                set bundleID to (clientInfo's bundleIdentifier()) as text
                
                return bundleID
            end run
            """

        guard let result = await runOsascript(script), !result.isEmpty else {
            return nil
        }
        return result
    }

    /// Fetches generic now playing info via MediaRemote (for non-Spotify/Apple Music sources).
    /// - Returns: NowPlayingInfo if media is playing, nil otherwise.
    func fetchGenericNowPlayingInfo() async -> NowPlayingInfo? {
        let script = """
            use framework "Foundation"
            use framework "AppKit"
            use scripting additions

            on run
                set MediaRemotePath to "/System/Library/PrivateFrameworks/MediaRemote.framework"
                set MediaRemoteBundle to current application's NSBundle's bundleWithPath:MediaRemotePath
                MediaRemoteBundle's load()
                
                set MRNowPlayingRequestClass to current application's NSClassFromString("MRNowPlayingRequest")
                
                set playerPath to MRNowPlayingRequestClass's localNowPlayingPlayerPath()
                set clientInfo to playerPath's client()
                set bundleID to (clientInfo's bundleIdentifier()) as text
                
                set nowPlayingItem to MRNowPlayingRequestClass's localNowPlayingItem()
                if nowPlayingItem is missing value then return ""
                set infoDict to nowPlayingItem's nowPlayingInfo()
                
                try
                    set theTitle to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoTitle") as text
                on error
                    set theTitle to ""
                end try
                try
                    set theArtist to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoArtist") as text
                on error
                    set theArtist to ""
                end try
                try
                    set theAlbum to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoAlbum") as text
                on error
                    set theAlbum to ""
                end try
                
                set playbackRate to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoPlaybackRate")
                set isPlaying to false
                if playbackRate is not missing value then
                    if (playbackRate's doubleValue()) > 0 then set isPlaying to true
                end if
                
                -- Duration and elapsed time
                set theDuration to 0
                set theElapsed to 0
                try
                    set durationVal to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoDuration")
                    if durationVal is not missing value then
                        set theDuration to (durationVal's doubleValue()) as real
                    end if
                end try
                try
                    set elapsedVal to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoElapsedTime")
                    if elapsedVal is not missing value then
                        set theElapsed to (elapsedVal's doubleValue()) as real
                    end if
                end try
                
                set tabChar to ASCII character 9
                set resultString to theTitle & tabChar & theArtist & tabChar & theAlbum & tabChar & (isPlaying as text) & tabChar & bundleID & tabChar & theDuration & tabChar & theElapsed
                
                return resultString
            end run
            """

        guard let result = await runOsascript(script), !result.isEmpty else {
            return nil
        }

        let parts = result.components(separatedBy: "\t")
        guard parts.count >= 7, !parts[0].isEmpty else { return nil }

        let totalTime = Double(parts[5].replacingOccurrences(of: ",", with: ".")) ?? 0
        let currentTime = Double(parts[6].replacingOccurrences(of: ",", with: ".")) ?? 0

        return NowPlayingInfo(
            title: parts[0],
            artist: parts[1],
            album: parts[2].isEmpty ? nil : parts[2],
            isPlaying: parts[3] == "true",
            sourceAppBundleID: parts[4].isEmpty ? nil : parts[4],
            totalTime: totalTime,
            currentTime: currentTime
        )
    }

    /// Fetches now playing info from Spotify.
    /// - Returns: NowPlayingInfo if Spotify is playing, nil otherwise.
    func fetchSpotifyInfo() async -> NowPlayingInfo? {
        let script = """
            if application "Spotify" is running then
                tell application "Spotify"
                    if player state is playing or player state is paused then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        set isPlaying to (player state is playing)
                        set durationMs to duration of current track
                        set currentSec to player position
                        return trackName & "\\t" & artistName & "\\t" & albumName & "\\t" & isPlaying & "\\t" & durationMs & "\\t" & currentSec
                    end if
                end tell
            end if
            return ""
            """

        guard let result = await AppleScriptRunner.runAppleScript(script),
            !result.isEmpty
        else {
            return nil
        }

        let parts = result.components(separatedBy: "\t")
        guard parts.count >= 6 else { return nil }

        // Spotify returns duration in milliseconds
        let totalTime = (Double(parts[4]) ?? 1000) / 1000.0
        let currentTime = Double(parts[5].replacingOccurrences(of: ",", with: ".")) ?? 0

        return NowPlayingInfo(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            isPlaying: parts[3] == "true",
            sourceAppBundleID: Self.spotifyBundleID,
            totalTime: totalTime,
            currentTime: min(currentTime, totalTime)
        )
    }

    /// Fetches now playing info from Apple Music.
    /// - Returns: NowPlayingInfo if Apple Music is playing, nil otherwise.
    func fetchAppleMusicInfo() async -> NowPlayingInfo? {
        let script = """
            if application "Music" is running then
                tell application "Music"
                    if player state is playing or player state is paused then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        set isPlaying to (player state is playing)
                        set durationSec to duration of current track
                        set currentSec to player position
                        return trackName & "\\t" & artistName & "\\t" & albumName & "\\t" & isPlaying & "\\t" & durationSec & "\\t" & currentSec
                    end if
                end tell
            end if
            return ""
            """

        guard let result = await AppleScriptRunner.runAppleScript(script),
            !result.isEmpty
        else {
            return nil
        }

        let parts = result.components(separatedBy: "\t")
        guard parts.count >= 6 else { return nil }

        // Apple Music returns duration in seconds
        let totalTime = Double(parts[4].replacingOccurrences(of: ",", with: ".")) ?? 1
        let currentTime = Double(parts[5].replacingOccurrences(of: ",", with: ".")) ?? 0

        return NowPlayingInfo(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            isPlaying: parts[3] == "true",
            sourceAppBundleID: Self.appleMusicBundleID,
            totalTime: totalTime,
            currentTime: min(currentTime, totalTime)
        )
    }

    // MARK: - Artwork

    /// Fetches artwork from Spotify (via artwork URL).
    /// - Returns: Image data if available, nil otherwise.
    func fetchSpotifyArtwork() async -> Data? {
        let script = """
            if application "Spotify" is running then
                tell application "Spotify"
                    if player state is not stopped then
                        return artwork url of current track
                    end if
                end tell
            end if
            return ""
            """

        guard let urlString = await AppleScriptRunner.runAppleScript(script),
            !urlString.isEmpty,
            let url = URL(string: urlString)
        else {
            return nil
        }

        return try? await URLSession.shared.data(from: url).0
    }

    /// Fetches artwork from Apple Music (via raw data).
    /// - Returns: NSImage if available, nil otherwise.
    func fetchAppleMusicArtwork() async -> NSImage? {
        return await Task.detached(priority: .userInitiated) { () -> NSImage? in
            let script = """
                tell application "Music"
                    if it is running then
                        get data of artwork 1 of current track
                    end if
                end tell
                """

            var error: NSDictionary?
            guard let scriptObject = NSAppleScript(source: script) else { return nil }
            let output = scriptObject.executeAndReturnError(&error)

            if error != nil {
                return nil
            }

            let data = output.data
            return NSImage(data: data)
        }.value
    }

    // MARK: - Private Helpers

    /// Runs an AppleScriptObjC script via osascript (required for MediaRemote access).
    private func runOsascript(_ script: String) async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - App Management

    /// Opens an app with the given bundle identifier.
    @MainActor
    func openApp(bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            Log.warning("App not found: \(bundleID)", category: .scripts)
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
            if let error = error {
                Task { @MainActor in
                    Log.error(
                        "Failed to open app: \(error.localizedDescription)", category: .scripts)
                }
            }
        }
    }
}
