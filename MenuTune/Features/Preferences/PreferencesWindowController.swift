//
//  PreferencesWindowController.swift
//  MenuTune
//
//  Window controller for displaying the preferences window.
//  Subclasses NSWindowController for proper AppKit integration (required for sidebar toggle).
//

import Cocoa
import SwiftUI

// MARK: - Preferences Window Controller

/// Window controller for displaying the preferences window.
/// Inherits from NSWindowController to get proper macOS window management including sidebar toggle.
class PreferencesWindowController: NSWindowController {

    private let preferences: PreferencesModel

    convenience init(preferences: PreferencesModel) {
        // Create window with modern style (like XKey's SettingsWindowController)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "MenuTune Preferences"
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.center()

        // Call designated initializer
        self.init(window: window, preferences: preferences)

        // Create SwiftUI view
        let preferencesView = PreferencesView(preferences: preferences)
        let hostingController = NSHostingController(rootView: preferencesView)
        window.contentViewController = hostingController
    }

    init(window: NSWindow, preferences: PreferencesModel) {
        self.preferences = preferences
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows the preferences window.
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
