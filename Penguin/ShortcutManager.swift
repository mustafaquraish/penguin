import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleSearchBar = KeyboardShortcuts.Name("toggleSearchBar")
}

extension KeyboardShortcuts.Name {
    var shortcutString: String? {
        KeyboardShortcuts.getShortcut(for: self)?.description
    }
}

/// Manages shortcuts for various commands in Penguin
public class ShortcutManager {
    public static let searchBarShortcut = KeyboardShortcuts.Name.toggleSearchBar
    private static var commandShortcuts: [String: KeyboardShortcuts.Name] = [:]

    public static func registerCommandShortcut(commandId: String, name: String)
        -> KeyboardShortcuts.Name
    {
        if let existingName = commandShortcuts[commandId] {
            return existingName
        }

        let shortcutId = commandId.replacingOccurrences(of: ".", with: "_")
        let shortcutName = KeyboardShortcuts.Name(shortcutId)
        commandShortcuts[commandId] = shortcutName
        return shortcutName
    }

    public static func getShortcutFor(commandId: String) -> KeyboardShortcuts.Name? {
        return commandShortcuts[commandId]
    }

    public static func getAllShortcuts() -> [String: KeyboardShortcuts.Name] {
        return commandShortcuts
    }

    public static func generateCommandId(extensionId: String, commandTitle: String) -> String {
        let sanitizedTitle =
            commandTitle
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "-", with: ".")
        return "\(extensionId).\(sanitizedTitle)"
    }
}
