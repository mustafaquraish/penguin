import KeyboardShortcuts
import SwiftUI

struct PreferencesView: View {
    var body: some View {
        TabView {
            ShortcutsPreferencesView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 500, height: 300)
        .padding()
    }
}

struct GeneralPreferencesView: View {
    var body: some View {
        Form {
            Text("General Settings")
                .font(.title2)
            // Add your general settings here
        }
    }
}

class ShortcutWindowController: NSWindowController {
    init(shortcutName: KeyboardShortcuts.Name) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 150, height: 50),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)
        window.contentView = KeyboardShortcuts.RecorderCocoa(for: shortcutName)

        /// remove buttons
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.setIsVisible(false)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFront(nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func close() {
        super.close()
    }
}

struct ShortcutsPreferencesView2: View {
    let commands: [Command] = ExtensionManager.shared.getAllCommands()

    private func onItemSelected(item: Command) {
        print("got item: \(item)")
        let windowController = ShortcutWindowController(shortcutName: item.shortcutName)
        windowController.showWindow(nil)
    }

    var body: some View {
        // Add your shortcuts settings here
        SearchableView(
            items: commands,
            fuzzyMatchKey: { item in item.title },
            onItemSelected: onItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            ScrollingSelectionList(
                items: filteredItems,
                selectedItem: selectedItem,
                focusedIndex: focusedIndex,
                onItemClicked: { _ in },
                onItemSelected: onItemSelected,
                elem: { item in
                    HStack {
                        Text(item.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        KeyboardShortcuts.Recorder(for: item.shortcutName)
                    }
                }
            )
        }
    }
}

struct ShortcutsPreferencesView: View {
    let commands: [Command] = ExtensionManager.shared.getAllCommands()
    @State private var searchText: String = ""
    private func onItemSelected(item: Command) {
        print("got item: \(item)")
        let windowController = ShortcutWindowController(shortcutName: item.shortcutName)
        windowController.showWindow(nil)
    }

    private var filteredCommands: [Command] {
        if searchText.isEmpty {
            return commands
        } else {
            return commands.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack {
            // Search field above everything, clearly separated
            TextField("Search", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(commands.filter { command in
                        searchText.isEmpty || command.title.localizedCaseInsensitiveContains(searchText)
                    }, id: \.shortcutName) { command in
                        HStack {
                            Text(command.title)
                            Spacer()
                            KeyboardShortcuts.Recorder(for: command.shortcutName)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
    }
}

class PreferencesWindowController: NSWindowController {
    private var previousActiveApp: NSRunningApplication?

    init(window: NSWindow, previousActiveApp: NSRunningApplication?) {
        self.previousActiveApp = previousActiveApp
        window.title = "Preferences"
        window.center()

        let hostingView = NSHostingView(
            rootView: ShortcutsPreferencesView2()
        )
        window.contentView = hostingView
        super.init(window: window)

        // Add notification observer for when window becomes key
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: window
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func close() {
        super.close()
        if let previousApp = previousActiveApp {
            previousApp.activate()
        }
    }

    @objc func cancel(_ sender: Any?) {
        close()
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        // Small delay to ensure views are loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Find the search field and make it first responder
            if let window = self.window,
                let searchField = window.contentView?.recursiveSubviews.first(where: {
                    $0 is NSSearchField
                })
            {
                window.makeFirstResponder(searchField)
            }
        }
    }
}

// Helper extension to find subviews
extension NSView {
    fileprivate var recursiveSubviews: [NSView] {
        return subviews + subviews.flatMap { $0.recursiveSubviews }
    }
}

//#Preview {
//    PreferencesView()
//}
