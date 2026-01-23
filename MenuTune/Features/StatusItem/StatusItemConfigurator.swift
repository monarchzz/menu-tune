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

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        button.title = ""
        button.image = nil
        button.target = target
        button.action = action
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        button.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            hostingView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])

        updateLength(statusItem, hostingView: hostingView)
    }

    static func updateLength(_ statusItem: NSStatusItem, hostingView: NSView) {
        if let hostingView = hostingView as? NSHostingView<StatusItemView> {
            hostingView.layout()
        }
        statusItem.length = hostingView.intrinsicContentSize.width
    }

    static func refreshLayout(_ statusItem: NSStatusItem) {
        guard let button = statusItem.button,
            let hostingView = button.subviews.first as? NSHostingView<StatusItemView>
        else {
            return
        }
        hostingView.needsLayout = true
        hostingView.layoutSubtreeIfNeeded()

        updateLength(statusItem, hostingView: hostingView)

        button.needsLayout = true
        button.layoutSubtreeIfNeeded()
    }
}
