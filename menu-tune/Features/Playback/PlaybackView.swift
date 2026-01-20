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
        ZStack {
            // Background material
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(width: 300, height: 300)
            
            content
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        let blurRadius: CGFloat = isHovering ? 5 : 0
        let overlayColor: Color? = isHovering ? Color.black.opacity(0.3) : nil
        
        ZStack {
            // Artwork layer
            artworkView
                .blur(radius: blurRadius)
                .overlay(overlayColor)
            
            // Controls overlay (appears on hover)
            if isHovering {
                controlsOverlay
                    .transition(.opacity)
            }
        }
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
            Color.gray.opacity(0.2)
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white.opacity(0.2))
                .frame(width: 100, height: 100)
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
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Settings gear button
            Button(action: { onOpenPreferences?() }) {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
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
            // Artist name
            Text(model.artist.isEmpty ? "Unknown Artist" : model.artist)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Playback buttons (only for controllable sources)
            if model.supportsControl {
                HStack(spacing: 10) {
                    playbackButton(imageName: "backward.fill", size: 30) {
                        model.skipBack()
                    }
                    
                    playbackButton(
                        imageName: model.isPlaying ? "pause.fill" : "play.fill",
                        size: 40
                    ) {
                        model.togglePlayPause()
                    }
                    
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
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 10)
            }
            
            // Track title
            Text(model.title.isEmpty ? "No Track" : model.title)
                .font(.title3)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Bottom Bar
    
    @ViewBuilder
    private var bottomBar: some View {
        if model.supportsControl {
            HStack(alignment: .center, spacing: 8) {
                // Current time
                Text(formatTime(model.currentTime, styleMatching: model.totalTime))
                    .font(.body.monospacedDigit())
                    .foregroundColor(.white)
                    .fixedSize(horizontal: true, vertical: false)
                
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
                    .foregroundColor(.white)
                    .fixedSize(horizontal: true, vertical: false)
            }
        } else {
            // Non-controllable source: show source indicator
            HStack {
                Spacer()
                Text(sourceLabel)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
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
    
    private func playbackButton(imageName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
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
