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

    // MARK: - Initialization

    init<Content: View>(contentView: Content, preferences: PreferencesModel) {
        self.window = PopoverWindow(rootView: contentView)
        self.preferences = preferences

        setupObservers()

        // Initial appearance update
        updateWindowAppearance()
    }

    private func setupObservers() {
        preferences.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // Defer slightly to ensure values are updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.updateWindowAppearance()
                }
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
        guard let button = button else { return }

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
            context.duration = 0.2
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.window.orderOut(nil)
            self?.window.alphaValue = 1
        }
    }

    // MARK: - Private Methods

    private func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window,
            let screen = buttonWindow.screen
        else { return }

        // Convert button frame to screen coordinates
        let buttonFrame = buttonWindow.convertToScreen(
            button.convert(button.bounds, to: nil)
        )

        let popoverSize = window.frame.size

        // Position below menu bar, centered on button
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let spacingBelowMenuBar: CGFloat = 0
        let totalOffset = menuBarHeight + spacingBelowMenuBar

        let popoverY = screen.frame.maxY - totalOffset - popoverSize.height
        let popoverX = buttonFrame.midX - popoverSize.width / 2

        // Keep popover on screen
        let clampedX = max(
            screen.visibleFrame.minX, min(popoverX, screen.visibleFrame.maxX - popoverSize.width))

        window.setFrameOrigin(NSPoint(x: clampedX, y: popoverY))
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)

        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1
        }
    }
}
