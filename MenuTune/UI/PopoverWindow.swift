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

    // MARK: - Properties

    private let visualEffectView: NSVisualEffectView

    // MARK: - Initialization

    init<Content: View>(rootView: Content) {
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

        configureWindow()
        setupContentView(rootView: rootView)
    }

    // MARK: - Configuration

    private func configureWindow() {
        isReleasedWhenClosed = false
        level = .floating
        collectionBehavior = [.transient, .canJoinAllSpaces]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        ignoresMouseEvents = false
        becomesKeyOnlyIfNeeded = true
    }

    private func setupContentView<Content: View>(rootView: Content) {
        // Create container view for proper corner masking
        let containerView = NSView(frame: visualEffectView.bounds)
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 12
        containerView.layer?.masksToBounds = true

        // Add visual effect view as background
        visualEffectView.autoresizingMask = [.width, .height]
        containerView.addSubview(visualEffectView)

        // Create hosting view with transparent background
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = containerView.bounds
        hostingView.autoresizingMask = [.width, .height]

        // Ensure hosting view is fully transparent
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false

        containerView.addSubview(hostingView)
        contentView = containerView
    }

    // MARK: - Window Behavior

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Resizing

    /// Resize the window to the specified content size, keeping the top-left corner fixed.
    /// - Parameter size: The new content size.
    func resize(to size: NSSize) {
        guard size != self.frame.size else { return }

        let currentFrame = self.frame
        let heightDelta = size.height - currentFrame.height

        // Adjust Y origin to keep the top edge fixed
        // (New Y) = (Old Y) - (Height Increase)
        let newY = currentFrame.origin.y - heightDelta

        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: newY,
            width: size.width,
            height: size.height
        )

        self.setFrame(newFrame, display: true, animate: true)
    }
}
