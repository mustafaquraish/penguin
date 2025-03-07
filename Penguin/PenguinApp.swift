import AppKit
import KeyboardShortcuts
import SwiftUI

@main
class Penguin: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var extensionManager: ExtensionManager = ExtensionManager.shared
    private var preferencesWindowController: NSWindowController?

    private var statusItem: NSStatusItem!

    // Add property to store the previously active app
    private var previousActiveApp: NSRunningApplication?

    // TODO: Have a view-stack and allow using esc to go back to the previous view
    //       (but only if we selected an item from the search results, not a hotkey)

    static func main() {
        let app = NSApplication.shared
        let delegate = Penguin()
        app.delegate = delegate
        app.run()
    }

    func runCommand(command: Command) {
        if let view = command.action() {
            setWindowView(view: view)
        }
    }

    func setDefaultView() {
        setWindowView(
            view: GlobalSearchView(
                // TODO: Cache all the commands
                items: extensionManager.getAllCommands(),
                onItemSelected: runCommand
            ))
    }

    func setWindowView(view: any View) {
        if let contentView = window?.contentView {
            contentView.removeFromSuperview()
        }
        let contentView =
            view
            .onKeyPress(.escape) {
                self.hideMainWindow()
                return .handled
            }
            .padding(.top, -25)  // Negative padding to remove the gap

        let hostingView = NSHostingView(rootView: AnyView(contentView))
        hostingView.autoresizingMask = [.width, .height]
        window?.contentView = hostingView
    }

    func setupMainWindow(commands: [Command]) {
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
        setWindowView(
            view: GlobalSearchView(
                items: commands,
                onItemSelected: runCommand
            ))

        // Critical for focus: Activate the app
        NSApp.setActivationPolicy(.accessory)  // Use .accessory for menu bar apps
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        previousActiveApp = NSWorkspace.shared.frontmostApplication

        setupStatusItem()

        // TODO: It is annoying to manually specify these... find some way to auto-register them.
        extensionManager.registerExtension(FruitExtension())
        extensionManager.registerExtension(TwoPanelExtension())
        extensionManager.registerExtension(NavigationPanelExtension())

        print("Fetching commands")
        // TODO: This is blocking the app from launching. Ideally, we should launch some background
        //       task to collect all commands and then launch the main window. Alternatively, make the
        //       getAllCommands() async and run it on a background thread. This is especially important
        //       when we add application search as an extension.
        let commands = extensionManager.getAllCommands()
        print("Commands fetched: \(commands.count)")

        setupMainWindow(commands: commands)
        setupShortcuts(commands: commands)
    }

    private func setupShortcuts(commands: [Command]) {
        // Set default shortcut for toggling search bar
        KeyboardShortcuts.onKeyUp(for: .toggleSearchBar) { [weak self] in
            self?.toggleSearchBar()
        }
        // Set cmd+ctrl+option+/ shortcut
        KeyboardShortcuts.setShortcut(
            KeyboardShortcuts.Shortcut(.slash, modifiers: [.command, .control, .option]),
            for: .toggleSearchBar
        )
        // Local monitoring for cmd+, to open preferences
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                self.openPreferences()
                return nil
            }
            return event
        }

        // Register shortcuts for all commands dynamically
        for command in commands {
            let commandId = ShortcutManager.generateCommandId(
                extensionId: command.extensionId,
                commandTitle: command.title
            )
            let shortcutName =
                ShortcutManager.getShortcutFor(commandId: commandId)
                ?? ShortcutManager.registerCommandShortcut(
                    commandId: commandId, name: command.title)
            print("Registered shortcut for command '\(command.title)': \(shortcutName)")
        }
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

    // New centralized method for hiding the window
    private func hideMainWindow() {
        window?.setIsVisible(false)
        // Restore focus to the previous app if we have one
        if let previousApp = previousActiveApp {
            previousApp.activate()
            previousActiveApp = nil
        }
    }

    // New centralized method for showing the window
    private func showMainWindow() {
        // Store currently active app before we take focus
        previousActiveApp = NSWorkspace.shared.frontmostApplication
        print("Previous active app: \(previousActiveApp?.localizedName ?? "None")")

        window?.setIsVisible(true)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleSearchBar() {
        if window?.isVisible == false {
            setDefaultView()
            showMainWindow()
        } else {
            hideMainWindow()
        }
    }

    @objc private func openPreferences() {
        // If preferences window exists, just bring it to front
        if let controller = preferencesWindowController {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Otherwise create a new window
        let preferencesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        // Create and store the window controller
        preferencesWindowController = PreferencesWindowController(
            window: preferencesWindow,
            previousActiveApp: previousActiveApp
        )
        preferencesWindowController?.showWindow(nil)

        // Bring preferences window to front
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow.makeKeyAndOrderFront(nil)
    }

    // Update window delegate method
    func windowDidResignKey(_ notification: Notification) {
        hideMainWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

