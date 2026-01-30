//
//  ArtworkView.swift
//  MenuTune
//
//  Extracted artwork display component from PlaybackView.
//

import SwiftUI

// MARK: - Artwork View

/// Displays album artwork from URL, NSImage, or fallback placeholder.
struct ArtworkView: View {

    // MARK: - Properties

    let imageURL: URL?
    let image: NSImage?
    let size: CGFloat

    // MARK: - Body

    var body: some View {
        if let url = imageURL {
            // Spotify: Load from URL
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                case .failure:
                    fallbackArtwork
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                @unknown default:
                    fallbackArtwork
                }
            }
        } else if let nsImage = image {
            // Apple Music: Use NSImage
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()
        } else {
            fallbackArtwork
        }
    }

    // MARK: - Fallback Artwork

    private var fallbackArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(.white.opacity(0.8))
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
    }
}
