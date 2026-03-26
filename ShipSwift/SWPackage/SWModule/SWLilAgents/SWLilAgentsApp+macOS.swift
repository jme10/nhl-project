// SWLilAgentsApp+macOS.swift
// App entry point, AppDelegate, and menu bar setup for lil-agents macOS dock companions.

import SwiftUI
import AppKit

// MARK: - App Entry

@main
struct SWLilAgentsApp: App {
    @NSApplicationDelegateAdaptor(SWLilAgentsAppDelegate.self) var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - App Delegate

final class SWLilAgentsAppDelegate: NSObject, NSApplicationDelegate {
    private var controller: SWLilAgentsController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        controller = SWLilAgentsController()
        controller?.start()

        setupMenuBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
        SWClaudeSession.killAllSessions()
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "lil agents")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        let menu = NSMenu()

        // Character toggles
        let bruceItem = NSMenuItem(title: "Bruce", action: #selector(toggleBruce(_:)), keyEquivalent: "1")
        bruceItem.target = self
        bruceItem.state = .on
        menu.addItem(bruceItem)

        let jazzItem = NSMenuItem(title: "Jazz", action: #selector(toggleJazz(_:)), keyEquivalent: "2")
        jazzItem.target = self
        jazzItem.state = .on
        menu.addItem(jazzItem)

        menu.addItem(.separator())

        // Sound toggle
        let soundItem = NSMenuItem(title: "Sound Effects", action: #selector(toggleSound(_:)), keyEquivalent: "s")
        soundItem.target = self
        soundItem.state = .on
        menu.addItem(soundItem)

        menu.addItem(.separator())

        // Theme submenu
        let themeMenu = NSMenu()
        for theme in SWPopoverTheme.allThemes {
            let item = NSMenuItem(title: theme.name, action: #selector(selectTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme.name
            if theme.name == controller?.currentThemeName {
                item.state = .on
            }
            themeMenu.addItem(item)
        }
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        menu.addItem(.separator())

        // Display submenu
        let displayMenu = NSMenu()
        let autoItem = NSMenuItem(title: "Auto (Main Display)", action: #selector(selectDisplay(_:)), keyEquivalent: "")
        autoItem.target = self
        autoItem.tag = -1
        autoItem.state = .on
        displayMenu.addItem(autoItem)

        for (index, screen) in NSScreen.screens.enumerated() {
            let name = screen.localizedName
            let item = NSMenuItem(title: name, action: #selector(selectDisplay(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            displayMenu.addItem(item)
        }
        let displayItem = NSMenuItem(title: "Display", action: nil, keyEquivalent: "")
        displayItem.submenu = displayMenu
        menu.addItem(displayItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit lil agents", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Menu Actions

    @objc private func toggleBruce(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        controller?.setCharacterVisible(name: "bruce", visible: sender.state == .on)
    }

    @objc private func toggleJazz(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        controller?.setCharacterVisible(name: "jazz", visible: sender.state == .on)
    }

    @objc private func toggleSound(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        controller?.soundEnabled = sender.state == .on
    }

    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let themeName = sender.representedObject as? String else { return }
        controller?.setTheme(named: themeName)

        // Update menu checkmarks
        if let themeMenu = sender.menu {
            for item in themeMenu.items {
                item.state = item == sender ? .on : .off
            }
        }
    }

    @objc private func selectDisplay(_ sender: NSMenuItem) {
        controller?.setPinnedDisplay(index: sender.tag)

        // Update menu checkmarks
        if let displayMenu = sender.menu {
            for item in displayMenu.items {
                item.state = item == sender ? .on : .off
            }
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
