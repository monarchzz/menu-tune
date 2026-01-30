//
//  TrackInfoView.swift
//  MenuTune
//
//  Extracted track info display component from PlaybackView.
//

import SwiftUI

// MARK: - Track Info View

/// Displays track title and artist with animated content transitions.
struct TrackInfoView: View {

    // MARK: - Properties

    let title: String
    let artist: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // Track title with content transition
            Text(title.isEmpty ? "No Track" : title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .contentTransition(.interpolate)
                .animation(.spring(duration: 0.3), value: title)

            // Artist name with content transition
            Text(artist.isEmpty ? "Unknown Artist" : artist)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .contentTransition(.interpolate)
                .animation(.spring(duration: 0.3), value: artist)
        }
    }
}
