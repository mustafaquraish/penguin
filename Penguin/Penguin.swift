import AppKit
import KeyboardShortcuts
import SwiftUI

class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { return true }
}

@main
struct StealthApp: App {
    @NSApplicationDelegateAdaptor(Penguin.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class Penguin: NSObject, NSApplicationDelegate, NSWindowDelegate {
    public static var shared: Penguin = Penguin()
    public static var penguinIcon_20: NSImage?
    public static var penguinIcon_64: NSImage?
    public var previousActiveApp: NSRunningApplication?

    var window: OverlayPanel?
    var extensionManager: ExtensionManager = ExtensionManager.shared
    private var clipboardManager =  ClipboardManager.shared

    private var preferencesWindowController: NSWindowController?
    private var statusItem: NSStatusItem!
    private var settingsCommand: Command?

    private var viewStack: [() -> (any View)?] = []

    // TODO: Have a view-stack and allow using esc to go back to the previous view
    //       (but only if we selected an item from the search results, not a hotkey)

    func runCommand(command: Command) {
        print("Running command: \(command.title)")
        if let view = command.action() {
            viewStack.append(command.action)
            setWindowView(view: view)
            if window?.isVisible == false {
                showMainWindow()
            }
        // If we have run the command, hide the main window
        } else {
            hideMainWindow()
        }
    }

    func setDefaultView() {
        let viewFunc: () -> (any View)? = { GlobalSearchView(onItemSelected: self.runCommand) }
        viewStack.append(viewFunc)
        setWindowView(
            view: GlobalSearchView(
                onItemSelected: runCommand
            ))
    }

    func setWindowView(view: any View) {
        if let contentView = window?.contentView {
            contentView.removeFromSuperview()
        }

        let contentView = view
        let hostingView = NSHostingView(rootView: AnyView(contentView))
        hostingView.autoresizingMask = [.width, .height]
        window?.contentView = hostingView
    }

    func setupMainWindow() {
        // Create the window and set the content view

        // FIXME: We can't paste anything into the search bar because the window is non-activating.
        //       We need to find some other way to make the window non-activating, while also retaining
        //       the ability for previous app to keep it's focus on text fields.
        window = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 500),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        guard let window = window else { return }
        window.delegate = self

        _ = GlobalSearchController(window: window)

        window.center()
        window.setIsVisible(false)
        window.backgroundColor = NSColor(white: 0.1, alpha: 0.99)
        window.hasShadow = true
        window.setFrameAutosaveName("Penguin")
        window.isReleasedWhenClosed = false

        window.isFloatingPanel = true
        window.becomesKeyOnlyIfNeeded = true
        window.level = .popUpMenu // Keeps it above normal windows without taking focus

        // Critical for focus: Activate the app
        NSApp.setActivationPolicy(.accessory)  // Use .accessory for menu bar apps
        NSApp.activate(ignoringOtherApps: true)

        // Show by default
        setDefaultView()
        showMainWindow()
    }

    func setupPenguinIcons() {
        Penguin.penguinIcon_64 = loadImage(named: "penguin_64")
        if Penguin.penguinIcon_64 == nil {
            Penguin.penguinIcon_64 = imageFromEmoji(emoji: "🐧", width: 20, height: 20)
        }
        if Penguin.penguinIcon_20 == nil {
            Penguin.penguinIcon_20 = resizeImage(image: Penguin.penguinIcon_64!, width: 20, height: 20)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Penguin.shared = self
        setupPenguinIcons()
        setupStatusItem()

        // TODO: It is annoying to manually specify these... find some way to auto-register them.
        extensionManager.registerExtension(WindowExtension())
        extensionManager.registerExtension(ClipboardExtension())
        extensionManager.registerExtension(BunnyExtension())

        let preferencesExtension = PreferencesExtension()
        extensionManager.registerExtension(preferencesExtension)
        assert(preferencesExtension.getCommands().count >= 1)
        settingsCommand = preferencesExtension.getCommands()[0]
        assert(settingsCommand?.title == "Preferences")

        extensionManager.registerExtension(SystemPreferencePanesExtension())
        extensionManager.registerExtension(ConfettiExtension())

        // TODO: Currently command ordering is defined by the order of registration.
        //       We need each command to track the last time it was invoked and sort by that.
        extensionManager.registerExtension(ApplicationsExtension())

        print("Fetching commands")
        // TODO: This is blocking the app from launching. Ideally, we should launch some background
        //       task to collect all commands and then launch the main window. Alternatively, make the
        //       getAllCommands() async and run it on a background thread. This is especially important
        //       when we add application search as an extension.
        let commands = extensionManager.getAllCommands()
        print("Commands fetched: \(commands.count)")

        setupMainWindow()
        setupShortcuts()
    }

    private func setupShortcuts() {
        let commands = extensionManager.getAllCommands()

        // Set default shortcut for toggling search bar
        KeyboardShortcuts.onKeyUp(for: .togglePenguinWindow) { [weak self] in
            self?.toggleSearchBar()
        }
        // Local monitoring for cmd+, to open preferences
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                if let settingsCommand = self.settingsCommand {
                    self.runCommand(command: settingsCommand)
                }
                return nil
            }
            return event
        }

        // Register shortcuts for all commands dynamically
        for command in commands {
            KeyboardShortcuts.onKeyUp(for: command.shortcutName) { [weak self] in
                self?.runCommand(command: command)
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = Penguin.penguinIcon_20
            button.action = #selector(toggleSearchBar)
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Search", action: #selector(toggleSearchBar), keyEquivalent: "O"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "Settings", action: #selector(openPreferences), keyEquivalent: ",")
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // New centralized method for hiding the window
    public func hideMainWindow() {
        viewStack = []
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
        if window?.isVisible == false {
            previousActiveApp = NSWorkspace.shared.frontmostApplication
            print("Previous active app: \(previousActiveApp?.localizedName ?? "None")")
        }

        window?.setIsVisible(true)
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        // NSApp.activate(ignoringOtherApps: true)
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
        if let settingsCommand = settingsCommand {
            runCommand(command: settingsCommand)
        }
    }

    @objc func cancel(_ sender: Any?) {
        print("Going back")
        _ = viewStack.popLast()
        if viewStack.count > 0 {
            if let view = viewStack.last?() {
                setWindowView(view: view)
            }
            showMainWindow()

        } else {
            hideMainWindow()
        }
    }

    // Close window when it loses focus
    func windowDidResignKey(_ notification: Notification) {
        hideMainWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

extension KeyboardShortcuts.Name {
    static let togglePenguinWindow = KeyboardShortcuts.Name("com.penguin.toggle")
}
