//
//  StatusItemConfigurator.swift
//  MenuTune
//
//  Helper to configure NSStatusItem with SwiftUI content.
//

import AppKit
import SwiftUI

// MARK: - Status Item Configurator

/// Configures the NSStatusItem with a SwiftUI-based view.
@MainActor
enum StatusItemConfigurator {
    
    /// Configures the status item button with a SwiftUI StatusItemView.
    /// - Parameters:
    ///   - statusItem: The NSStatusItem to configure.
    ///   - statusModel: The status item model for display state.
    ///   - preferences: The preferences model for display options.
    ///   - action: The action to perform when clicked.
    ///   - target: The target for the action.
    static func configure(
        _ statusItem: NSStatusItem,
        statusModel: StatusItemModel,
        preferences: PreferencesModel,
        action: Selector,
        target: AnyObject
    ) {
        guard let button = statusItem.button else { return }
        
        // Create the SwiftUI view
        let contentView = StatusItemView(
            statusModel: statusModel,
            preferences: preferences
        )
        
        // Create hosting view
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure button
        button.title = ""
        button.image = nil
        button.target = target
        button.action = action
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Add hosting view as subview
        button.addSubview(hostingView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: button.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])
        
        // Update the status item length
        updateLength(statusItem, hostingView: hostingView)
    }
    
    /// Updates the status item length based on content size.
    /// - Parameters:
    ///   - statusItem: The NSStatusItem to update.
    ///   - hostingView: The hosting view containing the SwiftUI content.
    static func updateLength(_ statusItem: NSStatusItem, hostingView: NSView) {
        let fittingSize = hostingView.fittingSize
        statusItem.length = fittingSize.width + 8 // Add padding
    }
    
    /// Forces a layout update on the status item.
    /// - Parameter statusItem: The NSStatusItem to update.
    static func refreshLayout(_ statusItem: NSStatusItem) {
        guard let button = statusItem.button,
              let hostingView = button.subviews.first as? NSHostingView<StatusItemView> else {
            return
        }
        // Mark for layout now, but defer calling `layoutSubtreeIfNeeded`
        // to avoid triggering layout while the view hierarchy is already
        // in the middle of a layout pass (which causes recursion).
        hostingView.needsLayout = true

        // Defer length recalculation to the next run loop cycle.
        // Avoid forcing a synchronous layout here because calling
        // `layoutSubtreeIfNeeded()` while the view hierarchy is already
        // being laid out can cause recursion and runtime warnings.
        DispatchQueue.main.async {
            updateLength(statusItem, hostingView: hostingView)
        }
    }
}
