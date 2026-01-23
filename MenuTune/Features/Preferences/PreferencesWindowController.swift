//
//  PreferencesWindowController.swift
//  MenuTune
//
//  Window controller for displaying the preferences window.
//

import Cocoa
import SwiftUI

// MARK: - Preferences Window Controller

/// Window controller for displaying the preferences window.
/// Inherits from NSWindowController to get proper macOS window management including sidebar toggle.
final class PreferencesWindowController: NSWindowController {

    // MARK: - Properties

    private let preferences: PreferencesModel

    // MARK: - Initialization

    convenience init(preferences: PreferencesModel) {
        // Create window with modern style
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Configure window properties
        window.title = "MenuTune Preferences"
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.toolbarStyle = .unified
        window.center()

        // Call designated initializer
        self.init(window: window, preferences: preferences)

        // Create SwiftUI view with hosting controller
        let preferencesView = PreferencesView(preferences: preferences)
        let hostingController = NSHostingController(rootView: preferencesView)
        window.contentViewController = hostingController
    }

    init(window: NSWindow, preferences: PreferencesModel) {
        self.preferences = preferences
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Window Management

    /// Shows the preferences window with activation.
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
