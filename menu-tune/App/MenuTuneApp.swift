//
//  MenuTuneApp.swift
//  MenuTune
//
//  A menu bar utility that displays "Now Playing" metadata.
//

import AppKit
import SwiftUI

@main
struct MenuTuneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // No visible windows - this is a menu bar only app
        Settings {
            EmptyView()
        }
    }
}
