//
//  MenuTuneApp.swift
//  Menu Tune
//
//  A menu bar utility that displays "Now Playing" metadata.
//

import AppKit
import SwiftUI

@main
struct MenuTuneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)
    }
}
