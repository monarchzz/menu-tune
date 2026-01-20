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
    
    init<Content: View>(rootView: Content) {
        let hostingView = NSHostingView(rootView: rootView)
        let contentRect = NSRect(x: 0, y: 0, width: 300, height: 300)
        
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
        
        // Configure hosting view
        hostingView.layer?.masksToBounds = true
        self.contentView = hostingView
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
