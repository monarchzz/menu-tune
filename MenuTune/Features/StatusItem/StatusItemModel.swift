//
//  StatusItemModel.swift
//  MenuTune
//
//  Model for the status bar item display state.
//

import AppKit
import Combine
import Foundation

// MARK: - Display Options

/// Options controlling what to display in the status bar.
struct StatusItemDisplayOptions {
    let showIcon: Bool
    let showMusicIcon: Bool
    let showText: Bool
    let showArtist: Bool
    let showTitle: Bool
    let maxWidth: CGFloat
}

// MARK: - Status Item Model

/// Observable model for status bar item display state.
@Observable
@MainActor
final class StatusItemModel {

    // MARK: - Observable Properties

    var artist: String = ""
    var title: String = ""
    var isPlaying: Bool = false
    var playerIconName: String = "sf.music.note"

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to NowPlayingService publisher
        NowPlayingService.shared.publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.artist = state.artist
                self.title = state.title
                self.isPlaying = state.isPlaying
                self.playerIconName = state.playerIconName
            }
            .store(in: &cancellables)
    }

    // MARK: - Display Logic

    /// Computes display options based on preferences and current state.
    func computeDisplayOptions(preferences: PreferencesModel) -> StatusItemDisplayOptions {
        let showMusicIcon = preferences.showMusicIcon && isPlaying

        // Hide text if paused and preference is set
        let performHideArtist = !isPlaying && preferences.hideArtistWhenPaused
        let performHideTitle = !isPlaying && preferences.hideTitleWhenPaused

        let showArtist = preferences.showArtist && !artist.isEmpty && !performHideArtist
        let showTitle = preferences.showTitle && !title.isEmpty && !performHideTitle

        let hasTextContent = !artist.isEmpty || !title.isEmpty
        let isTextDisplayEnabled = showArtist || showTitle
        let showText = hasTextContent && isTextDisplayEnabled

        // Show icon if preference enabled, or if nothing else to show
        let showIcon = preferences.showAppIcon || (!showMusicIcon && !showText)

        // Adjust spacing/width for compact view (handled in view, but model can pass flag or adjust max width if needed)
        // Here we just pass the raw max width, truncation happens in buildText

        return StatusItemDisplayOptions(
            showIcon: showIcon,
            showMusicIcon: showMusicIcon,
            showText: showText,
            showArtist: showArtist,
            showTitle: showTitle,
            maxWidth: preferences.maxStatusItemWidth
        )
    }

    /// Builds the display text based on options.
    func buildText(
        displayOptions: StatusItemDisplayOptions, preferences: PreferencesModel, font: NSFont
    ) -> String {
        let artistText = displayOptions.showArtist ? artist : nil
        let titleText = displayOptions.showTitle ? title : nil

        let label = [artistText, titleText]
            .compactMap { $0 }
            .joined(
                separator: (artistText != nil && titleText != nil)
                    ? preferences.customSeparator : "")

        return truncateText(label, font: font, maxWidth: displayOptions.maxWidth)
    }

    // MARK: - Private Methods

    private func measureTextWidth(_ text: String, font: NSFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return (text as NSString).size(withAttributes: attributes).width
    }

    private func truncateText(_ text: String, font: NSFont, maxWidth: CGFloat) -> String {
        let ellipsis = "…"
        if measureTextWidth(text, font: font) <= maxWidth {
            return text
        }

        var truncated = text
        while !truncated.isEmpty && measureTextWidth(truncated + ellipsis, font: font) > maxWidth {
            truncated = String(truncated.dropLast())
        }

        truncated = truncated.trimmingCharacters(in: .whitespacesAndNewlines)
        if truncated.hasSuffix("-") {
            truncated = String(truncated.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return truncated + ellipsis
    }
}
