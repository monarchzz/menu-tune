//
//  PlaybackControlsView.swift
//  MenuTune
//
//  Extracted playback control buttons from PlaybackView.
//

import SwiftUI

// MARK: - Playback Controls View

/// Displays playback control buttons (skip back, play/pause, skip forward).
struct PlaybackControlsView: View {

    // MARK: - Properties

    let isPlaying: Bool
    let onSkipBack: () -> Void
    let onPlayPause: () -> Void
    let onSkipForward: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            playbackButton(imageName: "backward.fill", size: 30, action: onSkipBack)
            playPauseButton
            playbackButton(imageName: "forward.fill", size: 30, action: onSkipForward)
        }
    }

    // MARK: - Play/Pause Button

    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(20)
                .contentShape(Rectangle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }

    // MARK: - Playback Button

    private func playbackButton(imageName: String, size: CGFloat, action: @escaping () -> Void)
        -> some View
    {
        Button(action: action) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .symbolEffect(.bounce, value: imageName)
    }
}
