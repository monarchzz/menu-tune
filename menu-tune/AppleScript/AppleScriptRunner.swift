//
//  AppleScriptRunner.swift
//  MenuTune
//
//  Centralized AppleScript runner. No scripts stored here.
//

import AppKit
import Foundation

// MARK: - AppleScript Runner

/// Centralized runner for executing AppleScript.
/// All script strings are stored in Scripts.swift.
final class AppleScriptRunner {
    private init() {}
    
    // MARK: - NSAppleScript Runner
    
    /// Executes AppleScript and returns string result.
    /// Use for simple AppleScript (tell app "Music", "Spotify", etc).
    static func runAppleScript(_ script: String) async -> String? {
        await Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            guard let scriptObject = NSAppleScript(source: script) else { return nil }
            let output = scriptObject.executeAndReturnError(&error)
            if error != nil { return nil }
            return output.stringValue
        }.value
    }
    
    /// Executes AppleScript and returns raw Data (for artwork).
    static func runAppleScriptForData(_ script: String) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            guard let scriptObject = NSAppleScript(source: script) else { return nil }
            let output = scriptObject.executeAndReturnError(&error)
            if error != nil { return nil }
            return output.data
        }.value
    }
    
    
    /// Runs a precompiled AppleScript resource (`.scpt`) bundled in the app resources.
    /// - Parameter resourceName: The base name of the compiled script (without extension).
    static func runAppleScriptObjCResource(named resourceName: String) async -> String? {
        // Look for compiled script in the app bundle resources
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "scpt") else { return nil }
        
        return await Task.detached(priority: .userInitiated) { () -> String? in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = [url.path]
            let outPipe = Pipe()
            process.standardOutput = outPipe
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                return nil
            }
            
            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            
            guard let output = String(data: outData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !output.isEmpty else { return nil }
            return output
        }.value
    }
    
    // MARK: - App Utilities
    
    /// Opens an app with the given bundle identifier.
    @MainActor
    static func openApp(bundleIdentifier: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            Log.warning("App not found: \(bundleIdentifier)", category: .scripts)
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
            if let error = error {
                Task { @MainActor in
                    Log.error("Failed to open app: \(error.localizedDescription)", category: .scripts)
                }
            }
        }
    }
}
