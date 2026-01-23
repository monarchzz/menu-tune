//
//  PlaybackView.swift
//  MenuTune
//
//  Main playback view displayed in the popover.
//

import SwiftUI

// MARK: - Playback View

/// Main playback view with album artwork and controls overlay.
struct PlaybackView: View {

    // MARK: - Properties

    @ObservedObject var model: PlaybackModel
    @ObservedObject var preferences: PreferencesModel
    @State private var isHovering = false

    /// Callback to open preferences window.
    var onOpenPreferences: (() -> Void)?

    // MARK: - Body

    var body: some View {
        content
            .frame(width: 300, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onHover { hovering in
                withAnimation(.spring(duration: 0.25, bounce: 0.1)) {
                    isHovering = hovering
                }
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        ZStack {
            // Artwork layer
            artworkView
                .blur(radius: isHovering ? 5 : 0)
                .overlay {
                    if isHovering {
                        Color.black.opacity(0.3)
                            .transition(.opacity)
                    }
                }

            // Controls overlay (appears on hover)
            if isHovering {
                controlsOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: isHovering)
    }

    // MARK: - Artwork View

    @ViewBuilder
    private var artworkView: some View {
        if let url = model.imageURL {
            // Spotify: Load from URL
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipped()
                case .failure:
                    fallbackArtwork
                case .empty:
                    ProgressView()
                        .frame(width: 300, height: 300)
                @unknown default:
                    fallbackArtwork
                }
            }
        } else if let nsImage = model.image {
            // Apple Music: Use NSImage
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .clipped()
        } else {
            fallbackArtwork
        }
    }

    private var fallbackArtwork: some View {
        ZStack {
            // Gradient background with corner radius
            LinearGradient(
                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Same layout as controlsOverlay
            VStack(spacing: 0) {
                Spacer()

                // Center content (like centerControls without playback buttons)
                VStack(spacing: 12) {
                    // Artist name
                    Text(model.artist.isEmpty ? "Unknown Artist" : model.artist)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    // Music note icon (instead of playback controls)
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.vertical, 10)
                        .symbolRenderingMode(.hierarchical)

                    // Track title
                    Text(model.title.isEmpty ? "No Track" : model.title)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(16)
        }
        .frame(width: 300, height: 300)
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            // Top bar: App icon and settings gear
            topBar

            Spacer()

            // Center: Track info and playback controls
            centerControls

            Spacer()

            // Bottom bar: Time and progress slider
            bottomBar
        }
        .padding(16)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // App icon button (opens music app)
            Button(action: { model.openMusicApp() }) {
                playerIconView
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            Spacer()

            // Settings gear button
            Button(action: { onOpenPreferences?() }) {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
        }
    }

    /// Player icon view that handles both asset and SF Symbol icons.
    @ViewBuilder
    private var playerIconView: some View {
        let iconName = model.playerIconName
        if iconName.hasPrefix("sf.") {
            // SF Symbol icon (for browser/generic sources)
            Image(systemName: String(iconName.dropFirst(3)))
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
        } else {
            // Asset icon (for Spotify/Apple Music)
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        }
    }

    // MARK: - Center Controls

    private var centerControls: some View {
        VStack(spacing: 12) {
            // Artist name with content transition
            Text(model.artist.isEmpty ? "Unknown Artist" : model.artist)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .contentTransition(.interpolate)
                .animation(.spring(duration: 0.3), value: model.artist)

            // Playback buttons (only for controllable sources)
            if model.supportsControl {
                HStack(spacing: 10) {
                    playbackButton(imageName: "backward.fill", size: 30) {
                        model.skipBack()
                    }

                    playPauseButton

                    playbackButton(imageName: "forward.fill", size: 30) {
                        model.skipForward()
                    }
                }
            } else {
                // Non-controllable source: show music note indicator
                Image(systemName: model.isPlaying ? "waveform" : "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 10)
                    .symbolEffect(.variableColor.iterative, isActive: model.isPlaying)
                    .symbolRenderingMode(.hierarchical)
            }

            // Track title with content transition
            Text(model.title.isEmpty ? "No Track" : model.title)
                .font(.title3)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .contentTransition(.interpolate)
                .animation(.spring(duration: 0.3), value: model.title)
        }
    }

    // MARK: - Play/Pause Button with Symbol Effect

    private var playPauseButton: some View {
        Button(action: { model.togglePlayPause() }) {
            Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
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

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        if model.supportsControl {
            HStack(alignment: .center, spacing: 8) {
                // Current time
                Text(formatTime(model.currentTime, styleMatching: model.totalTime))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: true, vertical: false)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.2), value: model.currentTime)

                // Progress slider
                CustomSlider(
                    value: Binding(
                        get: { model.currentTime },
                        set: { model.updatePlaybackPosition(to: $0) }
                    ),
                    range: 0...model.totalTime,
                    foregroundColor: .white,
                    trackColor: .white
                )
                .frame(maxWidth: .infinity)

                // Total time
                Text(formatTime(model.totalTime, styleMatching: model.totalTime))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: true, vertical: false)
            }
        } else {
            // Non-controllable source: show source indicator
            HStack {
                Spacer()
                Text(sourceLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }
        }
    }

    /// Label describing the playback source for non-controllable sources.
    private var sourceLabel: String {
        switch model.playerType {
        case .browser:
            return "Browser Playback"
        case .generic:
            return "External Playback"
        default:
            return ""
        }
    }

    // MARK: - Helper Views

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

    // MARK: - Time Formatting

    private func formatTime(_ seconds: Double, styleMatching total: Double) -> String {
        let s = Int(max(0, seconds))
        let t = Int(max(0, total))
        let (h, m, sec) = (s / 3600, (s % 3600) / 60, s % 60)
        let (th, tm) = (t / 3600, (t % 3600) / 60)

        if th > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        } else if tm >= 10 {
            return String(format: "%02d:%02d", m, sec)
        } else {
            return String(format: "%d:%02d", m, sec)
        }
    }
}
