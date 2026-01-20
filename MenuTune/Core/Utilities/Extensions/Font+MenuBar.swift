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
    static func menuBarText(weight: Font.Weight = .regular) -> Font {
        return .system(size: NSFont.menuBarFont(ofSize: 0).pointSize, weight: weight)
    }
}

// MARK: - NSFont Extension

extension NSFont {
    /// Returns the system menu bar font with specified size and weight.
    static func menuBarFont(ofSize size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        let fontSize = size > 0 ? size : NSFont.systemFontSize
        return NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: weight)
    }
}
