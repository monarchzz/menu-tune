//
//  NowPlayingInfo.swift
//  MenuTune
//
//  Model representing the current "Now Playing" metadata.
//

import Foundation

/// Represents metadata about the currently playing media.
/// This is a value type that can be safely passed across concurrency boundaries.
@preconcurrency
struct NowPlayingInfo: Equatable, Sendable {
    
    // MARK: - Properties
    
    /// The title of the current track.
    let title: String
    
    /// The artist of the current track.
    let artist: String
    
    /// The album name (optional).
    let album: String?
    
    /// Whether media is currently playing.
    let isPlaying: Bool
    
    /// The bundle identifier of the source app (e.g., "com.spotify.client").
    let sourceAppBundleID: String?
    
    // MARK: - Computed Properties
    
    /// Formatted display string: "Title - Artist" or just "Title" if no artist.
    var formattedTitle: String {
        if artist.isEmpty {
            return title
        }
        return "\(title) - \(artist)"
    }
    
    /// Returns true if this info has meaningful content to display.
    var hasContent: Bool {
        !title.isEmpty
    }
    
    // MARK: - Initialization
    
    nonisolated init(
        title: String,
        artist: String = "",
        album: String? = nil,
        isPlaying: Bool = false,
        sourceAppBundleID: String? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.sourceAppBundleID = sourceAppBundleID
    }
    
    // MARK: - Factory Methods
    
    /// Creates an empty placeholder info.
    nonisolated static var empty: NowPlayingInfo {
        NowPlayingInfo(title: "", artist: "", isPlaying: false)
    }
}

// MARK: - CustomStringConvertible

extension NowPlayingInfo: CustomStringConvertible {
    nonisolated var description: String {
        "NowPlayingInfo(title: \"\(title)\", artist: \"\(artist)\", isPlaying: \(isPlaying))"
    }
}
