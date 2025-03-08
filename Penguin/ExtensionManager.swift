import AppKit
import Cocoa
import KeyboardShortcuts
import SwiftUI

public struct Command {
    let title: String
    let subtitle: String?
    let icon: NSImage?
    let shortcutText: String?
    let shortcutName: KeyboardShortcuts.Name
    let action: () -> (any View)?
    let settingsView: () -> (any View)?

    public let extensionId: String
    public let extensionName: String

    public init(
        extensionId: String,
        extensionName: String,
        title: String,
        subtitle: String? = nil,
        icon: NSImage? = nil,
        shortcutText: String? = nil,
        shortcutName: KeyboardShortcuts.Name,
        action: @escaping () -> (any View)?,
        settingsView: @escaping () -> (any View)? = { nil }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.shortcutText = shortcutText
        self.shortcutName = shortcutName
        self.action = action
        self.settingsView = settingsView
        self.extensionId = extensionId
        self.extensionName = extensionName
    }
}

public func ShortcutCommand(
    extName: String,
    extIdentifier: String,
    title: String,
    subtitle: String,
    icon: NSImage? = nil,
    action: @escaping () -> (any View)? = { nil },
    settingsView: @escaping () -> (any View)? = { nil }
) -> Command {
    let shortcutId = ShortcutManager.generateCommandId(
        extensionId: extIdentifier,
        commandTitle: title
    )
    let name = "\(extName): \(title)"
    let shortcut =
        ShortcutManager.getShortcutFor(commandId: shortcutId)
        ?? ShortcutManager.registerCommandShortcut(
            commandId: shortcutId, name: name)
    return Command(
        extensionId: extIdentifier,
        extensionName: extName,
        title: title,
        subtitle: subtitle,
        icon: icon,
        shortcutText: shortcut.shortcutString,
        shortcutName: shortcut,
        action: action,
        settingsView: settingsView
    )
}

/// Protocol for extensions to implement
public protocol PenguinExtension {
    var identifier: String { get }
    var name: String { get }

    func getCommands() -> [Command]
    func getSettingsView() -> (any View)?
}

extension PenguinExtension {
    public func getSettingsView() -> (any View)? {
        nil
    }
}

/// Manages all extensions and coordinates search across them
public class ExtensionManager {
    public static let shared = ExtensionManager()

    private var extensions: [PenguinExtension] = []

    public init() {}

    /// Register a new extension
    public func registerExtension(_ extension: PenguinExtension) {
        extensions.append(`extension`)
    }

    /// Unregister an extension by identifier
    public func unregisterExtension(withIdentifier identifier: String) {
        extensions.removeAll { $0.identifier == identifier }
    }

    /// Get all available commands from all extensions
    public func getAllCommands() -> [Command] {
        extensions.flatMap { ext in
            ext.getCommands()
        }
    }
}

// Create a decorator i can use on an extension to automatically register it with the extension manager
@propertyWrapper
struct RegisterExtension {
    let wrappedValue: PenguinExtension

    init(wrappedValue: PenguinExtension) {
        self.wrappedValue = wrappedValue
        ExtensionManager.shared.registerExtension(wrappedValue)
    }
}
// MARK: - Helper Extensions

// extension NSRunningApplication {
//   var icon: NSImage? {
//     return NSWorkspace.shared.icon(forFile: bundleURL?.path ?? "")
//   }
// }

// extension KeyboardShortcuts.Name {
//   var shortcutString: String? {
//     KeyboardShortcuts.getShortcut(for: self)?.description
//   }
// }
