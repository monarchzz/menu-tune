//
//  LaunchAtLogin.swift
//  MenuTune
//
//  Helper for managing Launch at Login via SMAppService.
//

import AppKit
import ServiceManagement

struct LaunchAtLogin {
    /// Checks if the app is enabled to launch at login.
    static var isEnabled: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                Log.debug("Failed to toggle Launch at Login: \(error)", category: .app)
            }
        }
    }
}
