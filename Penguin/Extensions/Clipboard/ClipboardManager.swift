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

import Foundation
import Compression
import AppKit

import Foundation
import Compression
import AppKit

// Define content type enum
public enum ClipboardContentType: String, Codable {
    case text
    case image
}

// Public clipboard item class
public class ClipboardItem: Identifiable {
    public let id: UUID
    public var timestamp: Date
    public let contentType: ClipboardContentType
    public let previewText: String
    public let sizeBytes: Int

    // Full text is stored for text items
    public let text: String?

    // For image items, we use lazy loading
    private let imageLoader: (() -> NSImage?)?

    // Text item initializer (fully loaded)
    init(id: UUID, timestamp: Date, text: String, previewText: String, sizeBytes: Int) {
        self.id = id
        self.timestamp = timestamp
        self.contentType = .text
        self.text = text
        self.previewText = previewText
        self.sizeBytes = sizeBytes
        self.imageLoader = nil
    }

    // Image item initializer (lazy loaded)
    init(id: UUID, timestamp: Date, previewText: String, sizeBytes: Int, imageLoader: @escaping () -> NSImage?) {
        self.id = id
        self.timestamp = timestamp
        self.contentType = .image
        self.text = nil
        self.previewText = previewText
        self.sizeBytes = sizeBytes
        self.imageLoader = imageLoader
    }

    // Load image content on demand
    public func loadImage() -> NSImage? {
        return imageLoader?()
    }
}

// Internal storage model
fileprivate struct ClipboardItemStorage: Codable {
    let id: UUID
    let timestamp: Date
    let contentType: ClipboardContentType
    let text: String?
    let imageFilename: String?

    init(text: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.contentType = .text
        self.text = text
        self.imageFilename = nil
    }

    init(imageFilename: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.contentType = .image
        self.text = nil
        self.imageFilename = imageFilename
    }
}

class ClipboardManager: NSObject {
    public static let shared = ClipboardManager()

    @UserDefault<Int>(key: "clipboardmanager.maxItems", defaultValue: 100)
    public var maxItems: Int

    @UserDefault<Double>(key: "clipboardmanager.refreshTime", defaultValue: 0.5)
    public var refreshTime: Double

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let userDefaults = UserDefaults.standard
    private let metadataKey = "com.penguin.clipboardmanager.metadata"
    private let fileManager = FileManager.default
    private let dataDirectory: URL
    private let imagesDirectory: URL

    // Store all clipboard items in memory (text content loaded, images lazy loaded)
    private var clipboardItems: [ClipboardItem] = []

    private static let clipboardManagerIdentifierType = NSPasteboard.PasteboardType("com.penguin.clipboardmanager.identifier")


    override init() {
        // Create directories for storing clipboard data
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dataDirectory = appSupport.appendingPathComponent("ClipboardManager", isDirectory: true)
        imagesDirectory = dataDirectory.appendingPathComponent("Images", isDirectory: true)

        super.init()

        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        // Load items in background instead of blocking the main thread
        loadItemsInBackground()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods (unchanged API)

    public func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: refreshTime, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    public func updateRefreshTime(newRefreshTime: Double) {
        stopMonitoring()
        refreshTime = newRefreshTime
        startMonitoring()
    }

    public func search(query: String) -> [ClipboardItem] {
        if query.isEmpty {
            return getItems()
        }

        // Simple case-insensitive contains search on full text content
        return clipboardItems.filter { item in
            if item.contentType == .text, let text = item.text {
                return text.lowercased().contains(query.lowercased())
            }
            return false
        }
    }

    public func getItems() -> [ClipboardItem] {
        return clipboardItems
    }

    public func changeItemLastUsedToNow(item: ClipboardItem) {
        guard let index = clipboardItems.firstIndex(where: { $0.id == item.id }) else { return }
        clipboardItems[index].timestamp = Date()

        // Move the item to the front of the list
        let movedItem = clipboardItems.remove(at: index)
        clipboardItems.insert(movedItem, at: 0)

        saveMetadata()
    }

    public func closeMainWindowAndPasteItemIntoApplication(item: ClipboardItem) {
        Penguin.shared.hideMainWindow()

        // Put the item content on the system clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .text:
            if let text = item.text {
                // Create a pasteboard item with our identifier
                let pasteboardItem = NSPasteboardItem()
                pasteboardItem.setString(text, forType: .string)
                pasteboardItem.setString(item.id.uuidString, forType: ClipboardManager.clipboardManagerIdentifierType)

                // Write to pasteboard
                pasteboard.writeObjects([pasteboardItem])
            }

        case .image:
            if let image = item.loadImage() {
                // For images, we need to provide multiple representations
                if let tiffData = image.tiffRepresentation {
                    // Create a pasteboard item with our identifier
                    let pasteboardItem = NSPasteboardItem()

                    // Add TIFF representation
                    pasteboardItem.setData(tiffData, forType: .tiff)

                    // Add PNG representation if possible
                    if let bitmap = NSBitmapImageRep(data: tiffData),
                    let pngData = bitmap.representation(using: .png, properties: [:]) {
                        pasteboardItem.setData(pngData, forType: .png)
                    }

                    // Add our identifier
                    pasteboardItem.setString(item.id.uuidString, forType: ClipboardManager.clipboardManagerIdentifierType)

                    // Write to pasteboard
                    pasteboard.writeObjects([pasteboardItem])
                } else {
                    // Fallback if TIFF representation fails
                    pasteboard.writeObjects([image])
                }
            }
        }

        // Save current change count to prevent self-triggering
        lastChangeCount = pasteboard.changeCount

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

        // Update last used timestamp
        changeItemLastUsedToNow(item: item)
    }

    // MARK: - Private Methods

    private func checkClipboardChanges() {
        let pasteboard = NSPasteboard.general

        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount

            // Check if this is our own write by looking for our identifier
            if pasteboard.data(forType: ClipboardManager.clipboardManagerIdentifierType) != nil {
                // Skip processing our own clipboard writes
                return
            }

            // Check for image content first
            if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png),
            let image = NSImage(data: imageData) {
                addImageItem(image: image)
            }
            // Then check for text content
            else if let text = pasteboard.string(forType: .string), !text.isEmpty {
                addTextItem(text: text)
            }
        }
    }

    private func addTextItem(text: String) {
        // Generate preview - first line up to 100 chars
        let firstLine = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)[0]
        let previewText = firstLine.count > 100 ?
            String(firstLine.prefix(100)) + "..." :
            String(firstLine)

        // Check for duplicates
        if let existingIndex = clipboardItems.firstIndex(where: {
            guard $0.contentType == .text, let existingText = $0.text else { return false }
            return existingText == text
        }) {
            // Remove duplicate
            let duplicateId = clipboardItems[existingIndex].id
            clipboardItems.remove(at: existingIndex)
            deleteClipboardItemFile(id: duplicateId)
        }

        // Create storage item and save to disk
        let storageItem = ClipboardItemStorage(text: text)
        saveClipboardItemStorage(storageItem)

        // Create clipboard item with full text in memory
        let newItem = ClipboardItem(
            id: storageItem.id,
            timestamp: storageItem.timestamp,
            text: text,
            previewText: previewText,
            sizeBytes: text.utf8.count
        )

        // Add to memory
        clipboardItems.insert(newItem, at: 0)

        trimClipboardIfNeeded()
    }

    private func addImageItem(image: NSImage) {
        // Generate filename for the image
        let imageId = UUID()
        let imageFilename = "\(imageId.uuidString).png"

        // Save the image to disk
        if saveImage(image, filename: imageFilename) {
            // Create new storage item
            let storageItem = ClipboardItemStorage(imageFilename: imageFilename)
            saveClipboardItemStorage(storageItem)

            // Get file size
            let imagePath = imagesDirectory.appendingPathComponent(imageFilename)
            var sizeBytes = 0

            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: imagePath.path)
                if let fileSize = attributes[.size] as? Int {
                    sizeBytes = fileSize
                }
            } catch {
                print("Failed to get image size: \(error)")
            }

            // Create clipboard item with lazy image loading
            let newItem = ClipboardItem(
                id: storageItem.id,
                timestamp: storageItem.timestamp,
                previewText: "[Image]",
                sizeBytes: sizeBytes
            ) { [weak self] in
                guard let self = self,
                      let filename = imageFilename as String? else { return nil }
                return self.loadImageFile(filename: filename)
            }

            // Add to memory
            clipboardItems.insert(newItem, at: 0)

            trimClipboardIfNeeded()
        }
    }

    private func saveImage(_ image: NSImage, filename: String) -> Bool {
        let imageURL = imagesDirectory.appendingPathComponent(filename)

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: imageURL)
                return true
            } catch {
                print("Failed to save image: \(error)")
            }
        }
        return false
    }

    private func loadImageFile(filename: String) -> NSImage? {
        let imageURL = imagesDirectory.appendingPathComponent(filename)
        return NSImage(contentsOf: imageURL)
    }

    private func trimClipboardIfNeeded() {
        // Trim the list if necessary
        if clipboardItems.count > maxItems {
            // Get items to remove
            let itemsToRemove = clipboardItems.suffix(clipboardItems.count - maxItems)

            // Delete them from filesystem
            for item in itemsToRemove {
                deleteClipboardItemFile(id: item.id)
            }

            // Trim the in-memory list
            clipboardItems = Array(clipboardItems.prefix(maxItems))
        }

        // Save the metadata index
        saveMetadata()
    }

    private func saveClipboardItemStorage(_ item: ClipboardItemStorage) {
        let itemURL = dataDirectory.appendingPathComponent("\(item.id.uuidString).clipboard")

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(item)
            try data.write(to: itemURL, options: .atomic)
        } catch {
            print("Failed to save clipboard item: \(error)")
        }
    }

    private func deleteClipboardItemFile(id: UUID) {
        // Find the item
        guard let itemIndex = clipboardItems.firstIndex(where: { $0.id == id }) else { return }
        let item = clipboardItems[itemIndex]

        // Delete the item file
        let itemURL = dataDirectory.appendingPathComponent("\(id.uuidString).clipboard")
        try? fileManager.removeItem(at: itemURL)

        // If it's an image, also delete the image file
        if item.contentType == .image {
            // We need to find the filename from storage
            if let storageItem = loadClipboardItemStorage(id: id),
               let imageFilename = storageItem.imageFilename {
                let imageURL = imagesDirectory.appendingPathComponent(imageFilename)
                try? fileManager.removeItem(at: imageURL)
            }
        }
    }

    private func loadClipboardItemStorage(id: UUID) -> ClipboardItemStorage? {
        let itemURL = dataDirectory.appendingPathComponent("\(id.uuidString).clipboard")

        do {
            let data = try Data(contentsOf: itemURL)
            let decoder = JSONDecoder()
            return try decoder.decode(ClipboardItemStorage.self, from: data)
        } catch {
            print("Failed to load clipboard item storage: \(error)")
            return nil
        }
    }

    private func saveMetadata() {
        // Create simplified metadata for persistent storage
        let metadata = clipboardItems.map { item -> [String: Any] in
            let dict: [String: Any] = [
                "id": item.id.uuidString,
                "timestamp": item.timestamp,
                "contentType": item.contentType.rawValue,
                "sizeBytes": item.sizeBytes
            ]

            // No need to store the text content again, just reference it
            return dict
        }

        userDefaults.set(metadata, forKey: metadataKey)
    }

    private func loadItemsInBackground() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Load items in background
            let loadedItems = self.loadItems()
            print("ClipboardManager: Loaded \(loadedItems.count) items")

            // Update the UI on the main thread
            DispatchQueue.main.async {
                self.clipboardItems = loadedItems
            }
        }
    }

    private func loadItems() -> [ClipboardItem] {
        // First, try to get the metadata
        guard let metadataArray = userDefaults.array(forKey: metadataKey) as? [[String: Any]] else {
            return []
        }

        // Load all items from storage
        let items = metadataArray.compactMap { (metadataDict) -> ClipboardItem? in
            guard let idString = metadataDict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let timestamp = metadataDict["timestamp"] as? Date,
                  let contentTypeString = metadataDict["contentType"] as? String,
                  let contentType = ClipboardContentType(rawValue: contentTypeString) else {
                return nil
            }

            // Load the full item from storage
            guard let storageItem = loadClipboardItemStorage(id: id) else {
                return nil
            }

            // Create the appropriate ClipboardItem based on type
            if contentType == .text, let text = storageItem.text {
                // Generate preview
                let firstLine = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)[0]
                let previewText = firstLine.count > 100 ?
                    String(firstLine.prefix(100)) + "..." :
                    String(firstLine)

                // Return text item with full content in memory
                return ClipboardItem(
                    id: id,
                    timestamp: timestamp,
                    text: text,
                    previewText: previewText,
                    sizeBytes: text.utf8.count
                )
            } else if contentType == .image, let imageFilename = storageItem.imageFilename {
                // Get image size
                let sizeBytes = metadataDict["sizeBytes"] as? Int ?? 0

                // Return image item with lazy loading
                return ClipboardItem(
                    id: id,
                    timestamp: timestamp,
                    previewText: "[Image]",
                    sizeBytes: sizeBytes
                ) { [weak self] in
                    guard let self = self else { return nil }
                    return self.loadImageFile(filename: imageFilename)
                }
            }

            return nil
        }

        // Sort by timestamp (most recent first) and return
        return items.sorted { $0.timestamp > $1.timestamp }
    }
}
