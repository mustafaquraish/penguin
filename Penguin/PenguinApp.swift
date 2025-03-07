import AppKit
import SwiftUI

@main
struct PenguinApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Replace WindowGroup with Settings to prevent default window creation
        Settings {
            EmptyView()
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        // Create the window and set the content view
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 500),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        guard let window = window else { return }
        window.delegate = self

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.setIsVisible(false)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.backgroundColor = NSColor(white: 0.1, alpha: 0.9)
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.center()
        window.setFrameAutosaveName("Penguin 🐧")
        window.isReleasedWhenClosed = false
        window.level = .floating

        // Create the NSHostingView to hold our SwiftUI contentView
        let contentView =
            ContentView()
            .onKeyPress(.escape) {
                // Close the window when Escape is pressed
                window.setIsVisible(false)
                return .handled
            }
            .padding(.top, -25) // Negative padding to remove the gap

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView

        // Critical for focus: Activate the app
        NSApp.setActivationPolicy(.accessory)  // Use .accessory for menu bar apps
        NSApp.activate(ignoringOtherApps: true)

        // Set firstResponder to ensure focus works
        window.makeFirstResponder(hostingView)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            // Use a penguin emoji as our icon
            let penguinEmoji = "🐧"
            let penguinImage = NSImage(
                size: NSSize(width: 18, height: 18),
                flipped: false,
                drawingHandler: { (rect) in
                    penguinEmoji.draw(in: rect)
                    return true
                }
            )
            penguinImage.lockFocus()

            button.image = penguinImage
            button.action = #selector(toggleSearchBar)
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Search", action: #selector(toggleSearchBar), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: ",")
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // private func setupShortcuts() {
    //     // Register the global shortcut for toggling search bar
    //     KeyboardShortcuts.onKeyUp(for: .toggleSearchBar) { [weak self] in
    //         self?.toggleSearchBar()
    //     }

    //     // Register shortcuts for all commands dynamically
    //     for command in extensionManager.getAllCommands() {
    //         let commandId = ShortcutManager.generateCommandId(
    //             extensionId: command.extensionId,
    //             commandTitle: command.title
    //         )

    //         // Register this command with the shortcut manager if needed
    //         let shortcutName =
    //             ShortcutManager.getShortcutFor(commandId: commandId)
    //             ?? ShortcutManager.registerCommandShortcut(
    //                 commandId: commandId, name: command.title)

    //         print("Registered shortcut for command '\(command.title)': \(shortcutName)")
    //         // Set up the keyboard shortcut handler
    //         KeyboardShortcuts.onKeyUp(for: shortcutName) {
    //             command.action()
    //         }
    //     }
    // }

    @objc private func toggleSearchBar() {
        if window?.isVisible == false {
            window?.setIsVisible(true)
            // bring it to front and focus the search field
            NSApp.activate(ignoringOtherApps: true)

        } else {
            window?.setIsVisible(false)
        }
    }

    @objc private func openPreferences() {
        print("Open preferences")
    }

    // Close window when it loses focus
    func windowDidResignKey(_ notification: Notification) {
        window?.setIsVisible(false)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
