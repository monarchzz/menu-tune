//
//  PreferencesWindowController.swift
//  MenuTune
//
//  Window controller for displaying the preferences window.
//

import SwiftUI

// MARK: - Preferences Window Controller

/// Window controller for displaying the preferences window.
@MainActor
final class PreferencesWindowController {
    
    private var window: NSWindow?
    private let preferences: PreferencesModel
    
    init(preferences: PreferencesModel) {
        self.preferences = preferences
    }
    
    /// Shows the preferences window, creating it if necessary.
    func showWindow() {
        if let existingWindow = window, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let preferencesView = PreferencesView(preferences: preferences)
        let hostingController = NSHostingController(rootView: preferencesView)
        
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "MenuTune Preferences"
        newWindow.styleMask = [.titled, .closable]
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        
        self.window = newWindow
        
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
