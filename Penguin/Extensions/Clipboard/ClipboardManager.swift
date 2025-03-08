import Cocoa

public func closeMainWindowAndPasteTextIntoApplication(text: String) {
    Penguin.shared.hideMainWindow()

    addTextToClipboard(text: text)

    // Simulate Cmd+V keystroke
    let source = CGEventSource(stateID: .combinedSessionState)

    // Create key down event for Command+V
    let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)  // 0x09 is 'V'
    keyVDown?.flags = .maskCommand

    // Create key up event for Command+V
    let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
    keyVUp?.flags = .maskCommand

    // Post the events
    keyVDown?.post(tap: .cghidEventTap)
    keyVUp?.post(tap: .cghidEventTap)
}

public func addTextToClipboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

struct ClipboardItem: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: Date

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
    }
}

class ClipboardManager: NSObject {
    static let shared = ClipboardManager()

    // FIXME: Make this configurable
    private let maxItems = 100
    private var clipboardItems: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let userDefaults = UserDefaults.standard
    private let clipboardItemsKey = "com.penguin.clipboardmanager.items"

    override init() {
        super.init()
        loadItems()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    public func startMonitoring() {
        // Save the initial change count
        lastChangeCount = NSPasteboard.general.changeCount

        // Check for clipboard changes every second
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    public func search(query: String) -> [ClipboardItem] {
        if query.isEmpty {
            // Return all items if query is empty
            return clipboardItems
        }

        // Perform a simple fuzzy search
        return clipboardItems.filter { item in
            // Split query into characters for fuzzy matching
            let queryChars = Array(query.lowercased())
            let itemText = item.text.lowercased()

            var currentPos = 0

            // Try to find each character in sequence
            for char in queryChars {
                if let newPos = itemText.dropFirst(currentPos).firstIndex(of: char) {
                    currentPos = itemText.distance(from: itemText.startIndex, to: newPos) + 1
                } else {
                    return false
                }
            }

            return true
        }
    }

    public func getItems() -> [ClipboardItem] {
        return clipboardItems
    }

    // MARK: - Private Methods

    private func checkClipboardChanges() {
        let pasteboard = NSPasteboard.general

        // Check if the pasteboard has changed
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount

            // Only handle text content for now
            if let text = pasteboard.string(forType: .string), !text.isEmpty {
                addItem(text: text)
            }
        }
    }

    private func addItem(text: String) {
        // Check if this item already exists (to avoid duplicates)
        if let existingIndex = clipboardItems.firstIndex(where: { $0.text == text }) {
            // Remove the existing item (we'll add it again at the top)
            clipboardItems.remove(at: existingIndex)
        }

        // Add the new item at the beginning
        let newItem = ClipboardItem(text: text)
        clipboardItems.insert(newItem, at: 0)

        // Trim the list if necessary
        if clipboardItems.count > maxItems {
            clipboardItems = Array(clipboardItems.prefix(maxItems))
        }

        // Save the updated items
        saveItems()
    }

    private func saveItems() {
        // Encode the items
        if let encoded = try? JSONEncoder().encode(clipboardItems) {
            userDefaults.set(encoded, forKey: clipboardItemsKey)
        }
    }

    private func loadItems() {
        // Retrieve and decode the saved items
        if let data = userDefaults.data(forKey: clipboardItemsKey),
            let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        {
            clipboardItems = decoded
        }
    }
}
