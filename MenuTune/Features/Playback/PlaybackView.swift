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

    // MARK: - Constants

    private enum Layout {
        static let baseWidth: CGFloat = 300
        static let minHeight: CGFloat = 200
        static let maxHeight: CGFloat = 300
    }

    // MARK: - Properties

    var model: PlaybackModel
    @ObservedObject var preferences: PreferencesModel
    @State private var isHovering = false

    var onOpenPreferences: (() -> Void)?
    var onResize: ((CGSize) -> Void)?

    // MARK: - Body

    var body: some View {
        content
            .frame(width: viewSize.width, height: viewSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onHover { hovering in
                withAnimation(.spring(duration: 0.25, bounce: 0.1)) {
                    isHovering = hovering
                }
            }
            .frame(width: viewSize.width, height: viewSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onHover { hovering in
                withAnimation(.spring(duration: 0.25, bounce: 0.1)) {
                    isHovering = hovering
                }
            }
            .onChange(of: viewSize) { _, newSize in
                Log.debug("Requesting resize to: \(newSize.width)x\(newSize.height)", category: .ui)
                onResize?(newSize)
            }
            .onAppear {
                Log.debug("Initial view size: \(viewSize.width)x\(viewSize.height)", category: .ui)
                onResize?(viewSize)
            }
    }

    // MARK: - Computed Properties

    // MARK: - Computed Properties

    /// Dynamic view size based on artwork aspect ratio.
    /// - Standard: Width 300, Height = 300 / AspectRatio.
    /// - Min Height Check: If Height < 150, Width scales up to maintain AR.
    /// - Max Height Constraint: Height capped at 300.
    private var viewSize: CGSize {
        guard let image = model.image, image.size.height > 0, image.size.width > 0 else {
            return CGSize(width: Layout.baseWidth, height: Layout.maxHeight)
        }

        let aspectRatio = image.size.width / image.size.height

        // Calculate height at base width
        let heightAtBaseWidth = Layout.baseWidth / aspectRatio

        if heightAtBaseWidth < Layout.minHeight {
            // Too short (wide panoramic image), enforce min height and scale width
            // Height = Width / AR  =>  Width = Height * AR
            let newWidth = Layout.minHeight * aspectRatio
            return CGSize(width: newWidth, height: Layout.minHeight)
        } else {
            // Sufficient height or too tall (portrait)
            // Cap height at max height
            return CGSize(width: Layout.baseWidth, height: min(heightAtBaseWidth, Layout.maxHeight))
        }
    }

    private var hoverTintColor: Color {
        if let color = Color(hex: preferences.hoverTintColorHex) {
            return color
        }
        return Color.black
    }

    /// Blur radius based on preference.
    private var blurRadius: CGFloat {
        CGFloat(preferences.blurIntensity * 10)  // Scale 0-1 to 0-10
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        ZStack {
            // Artwork layer
            artworkView
                .blur(radius: shouldShowOverlay ? blurRadius : 0)
                .overlay {
                    if shouldShowOverlay {
                        hoverTintColor.opacity(preferences.hoverTintOpacity)
                            .transition(.opacity)
                    }
                }

            // Controls overlay (appears on hover when artwork is present)
            if shouldShowOverlay {
                controlsOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: isHovering)
    }

    /// Whether to show the controls overlay on hover (when artwork is present).
    private var shouldShowOverlay: Bool {
        isHovering && model.image != nil
    }

    // MARK: - Artwork View

    @ViewBuilder
    private var artworkView: some View {
        if let nsImage = model.image {
            // Display artwork with dynamic size
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
                .frame(width: viewSize.width, height: viewSize.height)
                .clipped()
        } else {
            fallbackArtwork
        }
    }

    private var fallbackArtwork: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Always visible content for non-controllable or idle state
            VStack(spacing: 16) {
                topBar
                Spacer()
                // Music note indicator
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(.white.opacity(0.8))
                    .symbolRenderingMode(.hierarchical)
                Spacer()
                // Track info and source label at the bottom
                VStack(spacing: 16) {
                    trackInfo
                    if !model.supportsControl {
                        Text(sourceLabel)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

            }
            .padding(16)
        }
        .frame(width: Layout.baseWidth, height: Layout.baseWidth)  // Square fallback
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            // Top bar: App icon and settings gear
            topBar

            Spacer()

            // Center: Playback controls / indicator
            centerControls

            Spacer()

            // Bottom section: Track info and progress
            VStack(spacing: 16) {
                trackInfo
                bottomBar
            }
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
        PlaybackControlsView(
            isPlaying: model.isPlaying,
            supportsControl: model.supportsControl,
            onSkipBack: { model.skipBack() },
            onPlayPause: { model.togglePlayPause() },
            onSkipForward: { model.skipForward() }
        )
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        TrackInfoView(title: model.title, artist: model.artist)
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 8) {
            // Progress bar with times (shown only for controllable sources)
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
                        range: 0...max(model.totalTime, 1),
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
            }

            Text(sourceLabel)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

        }
    }

    /// Label describing the playback source for non-controllable sources.
    private var sourceLabel: String {
        switch model.playerType {
        case .browser:
            return "Browser Playback"
        case .generic:
            return "External Playback"
        case .appleMusic:
            return "Apple Music"
        case .spotify:
            return "Spotify"
        default:
            return ""
        }
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
