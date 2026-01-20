//
//  Font+MenuBar.swift
//  MenuTune
//
//  Font extension for menu bar styling.
//

import SwiftUI

// MARK: - Font Extension

extension Font {
    /// Menu bar text font matching system style.
    static var menuBarText: Font {
        .system(size: NSFont.menuBarFont(ofSize: 0).pointSize)
    }
}
