//
//  PopoverManager.swift
//  MenuTune
//
//  Manages showing and hiding the playback popover.
//

import AppKit
import SwiftUI

// MARK: - Popover Manager

/// Manages the playback popover window visibility and positioning.
@MainActor
final class PopoverManager {

    // MARK: - Properties

    private var window: PopoverWindow
    private let preferences: PreferencesModel

    /// Animation duration for show/hide transitions
    private let animationDuration: TimeInterval = 0.2

    // MARK: - Initialization

    init<Content: View>(contentView: Content, preferences: PreferencesModel) {
        self.window = PopoverWindow(rootView: contentView)
        self.preferences = preferences
    }

    // MARK: - Public Methods

    /// Toggles the popover visibility relative to the status bar button.
    func toggle(relativeTo button: NSStatusBarButton?) {
        guard let button else { return }

        if window.isVisible {
            dismiss()
        } else {
            show(relativeTo: button)
        }

    }

    /// Dismisses the popover with animation.
    func dismiss() {
        guard window.isVisible else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                self?.window.orderOut(nil)
                self?.window.alphaValue = 1
            }
        }
    }

    /// Resizes the popover window to the specified size.
    func resize(to size: CGSize) {
        window.resize(to: size)
    }

    // MARK: - Private Methods

    private func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window,
            let screen = buttonWindow.screen
        else { return }

        // Calculate position
        let position = calculatePosition(for: button, in: screen, buttonWindow: buttonWindow)

        // Show with animation
        window.setFrameOrigin(position)
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
    }

    private func calculatePosition(
        for button: NSStatusBarButton,
        in screen: NSScreen,
        buttonWindow: NSWindow
    ) -> NSPoint {
        // Convert button frame to screen coordinates
        let buttonFrame = buttonWindow.convertToScreen(
            button.convert(button.bounds, to: nil)
        )

        let popoverSize = window.frame.size

        // Position below menu bar, centered on button
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let popoverY = screen.frame.maxY - menuBarHeight - popoverSize.height
        let popoverX = buttonFrame.midX - popoverSize.width / 2

        // Keep popover on screen
        let clampedX = max(
            screen.visibleFrame.minX,
            min(popoverX, screen.visibleFrame.maxX - popoverSize.width)
        )

        return NSPoint(x: clampedX, y: popoverY)
    }
}
