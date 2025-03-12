import AppKit
import Cocoa
import KeyboardShortcuts
import SwiftUI

public struct Command: Identifiable {
    public let id: String
    let title: String
    let subtitle: String?
    let icon: NSImage?
    let shortcutName: KeyboardShortcuts.Name
    let action: () -> (any View)?
    let settingsView: () -> (any View)?

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: NSImage? = nil,
        action: @escaping () -> (any View)?,
        settingsView: @escaping () -> (any View)? = { nil }
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.shortcutName = KeyboardShortcuts.Name(id)
        self.action = action
        self.settingsView = settingsView
    }
}

func generateCommandId(extensionId: String, commandTitle: String) -> String {
    let sanitizedTitle =
        commandTitle
        .lowercased()
        .replacingOccurrences(of: ":", with: "")
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: ".", with: "_")
    return "\(extensionId).\(sanitizedTitle)"
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

    public func makeCommand(
        title: String,
        subtitle: String,
        icon: NSImage? = nil,
        action: @escaping () -> (any View)? = { nil },
        settingsView: @escaping () -> (any View)? = { nil }
    ) -> Command {
        let shortcutId = generateCommandId(
            extensionId: identifier,
            commandTitle: title
        )
        return Command(
            id: shortcutId,
            title: title,
            subtitle: subtitle,
            icon: icon,
            action: action,
            settingsView: settingsView
        )
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
        // TODO: Cache all the commands, but need some way of handling changes to extensions / applications
        extensions.flatMap { ext in
            ext.getCommands()
        }
    }
}

// MARK: - Helper Extensions
