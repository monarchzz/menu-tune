//
//  Log.swift
//  MenuTune
//
//  Centralized logging utility for MenuTune.
//  Uses os.log with DEBUG-only verbose logging for optimal production performance.
//
//  Best Practices:
//  - Use Log.debug() for development diagnostics (disabled in Release)
//  - Use Log.info() for notable events (always logged)
//  - Use Log.warning() for recoverable issues
//  - Use Log.error() for failures that need attention
//

import Foundation
import os.log

// MARK: - Log Categories

/// Available logging categories for different subsystems.
enum LogCategory: String {
    case app = "App"
    case playback = "Playback"
    case services = "Services"
    case scripts = "Scripts"
    case spotify = "Spotify"
    case appleMusic = "AppleMusic"
    case statusItem = "StatusItem"
    case ui = "UI"
}

// MARK: - Log

/// Centralized logging utility for MenuTune.
///
/// Debug logs are completely compiled out in Release builds for zero overhead.
/// Info, warning, and error logs are always available for production diagnostics.
enum Log {

    // MARK: - Properties

    private static let subsystem = "com.hieunt0220.MenuTune"

    /// Cache of loggers by category for performance.
    private static var loggers: [LogCategory: Logger] = [:]

    /// Returns a logger for the specified category.
    private static func logger(for category: LogCategory) -> Logger {
        if let existing = loggers[category] {
            return existing
        }
        let newLogger = Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = newLogger
        return newLogger
    }

    // MARK: - Debug (Disabled in Release)

    /// Logs a debug message. **Completely disabled in Release builds.**
    ///
    /// Use for verbose development diagnostics that would be too noisy in production.
    /// Examples: fetch results, state changes, method entry/exit.
    ///
    /// - Parameters:
    ///   - message: The debug message.
    ///   - category: The logging category.
    static func debug(_ message: String, category: LogCategory = .app) {
        #if DEBUG
            logger(for: category).debug("\(message, privacy: .public)")
        #endif
    }

    // MARK: - Info (Always Available)

    /// Logs an informational message. **Always logged.**
    ///
    /// Use for notable events like app lifecycle, successful operations.
    /// Examples: app start/stop, major state transitions.
    ///
    /// - Parameters:
    ///   - message: The info message.
    ///   - category: The logging category.
    static func info(_ message: String, category: LogCategory = .app) {
        logger(for: category).info("\(message, privacy: .public)")
    }

    // MARK: - Warning (Always Available)

    /// Logs a warning message. **Always logged.**
    ///
    /// Use for recoverable issues that don't prevent operation.
    /// Examples: missing optional data, fallback behavior triggered.
    ///
    /// - Parameters:
    ///   - message: The warning message.
    ///   - category: The logging category.
    static func warning(_ message: String, category: LogCategory = .app) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    // MARK: - Error (Always Available)

    /// Logs an error message. **Always logged.**
    ///
    /// Use for failures that need attention but don't crash.
    /// Examples: script execution failed, resource not found.
    ///
    /// - Parameters:
    ///   - message: The error message.
    ///   - category: The logging category.
    static func error(_ message: String, category: LogCategory = .app) {
        logger(for: category).error("\(message, privacy: .public)")
    }
}
