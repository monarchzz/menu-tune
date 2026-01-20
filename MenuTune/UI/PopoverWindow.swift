//
//  PopoverWindow.swift
//  MenuTune
//
//  Custom floating panel for the playback popover.
//

import AppKit
import SwiftUI

// MARK: - Popover Window

/// Custom NSPanel for displaying the playback popover.
/// Floats above other windows and dismisses on outside click.
final class PopoverWindow: NSPanel {

    private let visualEffectView: NSVisualEffectView

    init<Content: View>(rootView: Content) {
        let hostingView = NSHostingView(rootView: rootView)
        let contentRect = NSRect(x: 0, y: 0, width: 300, height: 300)

        // Setup Visual Effect View
        visualEffectView = NSVisualEffectView(frame: contentRect)
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true

        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: true
        )

        // Window configuration
        self.isReleasedWhenClosed = false
        self.level = .floating
        self.collectionBehavior = [.transient, .canJoinAllSpaces]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.ignoresMouseEvents = false
        self.becomesKeyOnlyIfNeeded = true

        // View Hierarchy
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.frame = visualEffectView.bounds
        hostingView.autoresizingMask = [.width, .height]

        visualEffectView.addSubview(hostingView)
        self.contentView = visualEffectView
    }

    /// Updates the window appearance based on preferences.
    func updateAppearance(blurIntensity: Double, tintColorHex: String, theme: AppearanceTheme) {
        // Apply theme (Appearance)
        switch theme {
        case .system:
            self.appearance = nil
        case .light:
            self.appearance = NSAppearance(named: .aqua)
        case .dark:
            self.appearance = NSAppearance(named: .darkAqua)
        }

        // Apply Tint (via layer background color)
        // blurIntensity is handled by material choice typically, but we can adjust alpha of a tint layer if we had one.
        // For now, let's just stick to material.

        // If tintColor is provided, we might need an overlay view.
        // For simplicity, we'll verify this works first.
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }
}
