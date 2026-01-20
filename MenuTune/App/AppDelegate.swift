//
//  AppDelegate.swift
//  MenuTune
//
//  Application delegate for menu bar app lifecycle.
//  Wires together the new SpotMenu-style popover UI.
//

import AppKit
import Combine
import SwiftUI

/// Main application delegate that manages the menu bar app lifecycle.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var popoverManager: PopoverManager!
    private var preferencesWindowController: PreferencesWindowController!
    private var globalEventMonitor: Any?

    private let playbackModel = PlaybackModel()
    private let statusModel = StatusItemModel()
    private let preferences = PreferencesModel()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.info("MenuTune starting up...", category: .app)

        // Initialize status item
        setupStatusItem()

        // Initialize popover manager with PlaybackView
        setupPopover()

        // Initialize preferences window controller
        preferencesWindowController = PreferencesWindowController(preferences: preferences)

        // Setup observers
        setupObservers()

        // Setup global click monitor to dismiss popover
        setupGlobalEventMonitor()

        // Initial sync of app behavior
        syncAppBehavior()

        // Start NowPlayingService
        NowPlayingService.shared.start()

        Log.info("MenuTune initialized successfully", category: .app)
    }

    func applicationWillTerminate(_ notification: Notification) {
        Log.info("MenuTune shutting down...", category: .app)

        NowPlayingService.shared.stop()

        // Remove event monitor
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Setup Methods

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        StatusItemConfigurator.configure(
            statusItem,
            statusModel: statusModel,
            preferences: preferences,
            action: #selector(statusItemClicked(_:)),
            target: self
        )
    }

    private func setupPopover() {
        let playbackView = PlaybackView(
            model: playbackModel,
            preferences: preferences,
            onOpenPreferences: { [weak self] in
                self?.preferencesAction()
            }
        )
        popoverManager = PopoverManager(contentView: playbackView, preferences: preferences)
    }

    private func setupObservers() {
        // Observe preference changes
        preferences.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // Delay slightly to allow @AppStorage to update
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.refreshStatusItem()
                    self?.syncAppBehavior()
                }
            }
            .store(in: &cancellables)
    }

    private func setupGlobalEventMonitor() {
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown, .rightMouseDown,
        ]) { [weak self] _ in
            self?.popoverManager.dismiss()
        }
    }

    private func syncAppBehavior() {
        // Sync Launch at Login
        if LaunchAtLogin.isEnabled != preferences.launchAtLogin {
            LaunchAtLogin.isEnabled = preferences.launchAtLogin
        }

        // Sync Dock Icon
        // LSUIElement=true (Info.plist) makes it .accessory by default.
        // If hideDockIcon is FALSE effectively means "Show Dock Icon".
        // If hideDockIcon is TRUE means "Hide Dock Icon" (.accessory).
        let shouldHide = preferences.hideDockIcon
        let currentPolicy = NSApp.activationPolicy()

        if shouldHide && currentPolicy == .regular {
            NSApp.setActivationPolicy(.accessory)
        } else if !shouldHide && currentPolicy == .accessory {
            NSApp.setActivationPolicy(.regular)
        }
    }

    // MARK: - Status Bar Actions

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        popoverManager.toggle(relativeTo: statusItem.button)
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(
            NSMenuItem(title: "Refresh", action: #selector(refreshAction), keyEquivalent: "r"))
        menu.addItem(
            NSMenuItem(
                title: "Preferences...", action: #selector(preferencesAction), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "Quit MenuTune", action: #selector(quitAction), keyEquivalent: "q"))

        // Show menu
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil  // Remove menu after showing
    }

    // MARK: - Menu Actions

    @objc private func refreshAction() {
        Log.debug("Manual refresh requested", category: .app)
        Task { @MainActor in
            await playbackModel.fetchInfo()
        }
    }

    @objc private func preferencesAction() {
        Log.debug("Opening preferences", category: .app)
        popoverManager.dismiss()
        preferencesWindowController.showWindow()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }

    // MARK: - Private Methods

    private func refreshStatusItem() {
        StatusItemConfigurator.refreshLayout(statusItem)
    }
}
