//
//  PopoverManager.swift
//  MenuTune
//
//  Manages showing and hiding the playback popover.
//

import AppKit
import Combine
import SwiftUI

// MARK: - Popover Manager

/// Manages the playback popover window visibility and positioning.
@MainActor
final class PopoverManager {

    // MARK: - Properties

    private var window: PopoverWindow
    private let preferences: PreferencesModel
    private var cancellables = Set<AnyCancellable>()

    /// Animation duration for show/hide transitions
    private let animationDuration: TimeInterval = 0.2

    // MARK: - Initialization

    init<Content: View>(contentView: Content, preferences: PreferencesModel) {
        self.window = PopoverWindow(rootView: contentView)
        self.preferences = preferences

        setupObservers()
        updateWindowAppearance()
    }

    // MARK: - Observers

    private func setupObservers() {
        preferences.objectWillChange
            .receive(on: RunLoop.main)
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWindowAppearance()
            }
            .store(in: &cancellables)
    }

    private func updateWindowAppearance() {
        window.updateAppearance(
            blurIntensity: preferences.blurIntensity,
            tintColorHex: preferences.hoverTintColorHex,
            theme: preferences.appearanceTheme
        )
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
