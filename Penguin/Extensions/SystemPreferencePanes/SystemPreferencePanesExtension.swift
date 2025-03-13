import Foundation
import AppKit

// Some of these don't seem to work. Others are weird or not useful.
let blacklist: Set<String> = [
    "Time Machine",
    "Network",
    "Desktop Screen Effects",
    "Battery",
    "Dock",
    "Appearance",
    "Family Sharing",
    "Digi Hub Discs",
    "Classroom Settings",
    "Speech",
    "Extensions",
    "Print And Scan",
    "Expose",
    "Date And Time",
    "Print And Fax",
    "Energy Saver",
    "Class Kit Preference",
    "Profiles",
    "Universal Access",
    "Startup Disk",
]

func listPreferencePanes() -> [String: String] {
    let searchPaths = [
        "/System/Library/PreferencePanes/",
        "/System/Library/PreferenceBundles/"
    ]

    var paneList: [String: String] = [:]

    for path in searchPaths {
        if let items = try? FileManager.default.contentsOfDirectory(atPath: path) {
            for item in items where item.hasSuffix(".prefPane") {
                let fullPath = (path as NSString).appendingPathComponent(item)
                let formattedName = formatPreferencePaneName(item)
                if blacklist.contains(formattedName) || paneList.keys.contains(formattedName) {
                    continue
                }

                paneList[formattedName] = fullPath
            }
        }
    }

    return paneList
}

func formatPreferencePaneName(_ filename: String) -> String {
    // Remove file extensions
    var name = filename.replacingOccurrences(of: ".prefPane", with: "")
                      .replacingOccurrences(of: ".bundle", with: "")

    // Remove "Pref" or "PrefPane" suffix
    for suffix in ["PrefPane", "Pref", "Pane"] {
        if name.hasSuffix(suffix) {
            name = name.replacingOccurrences(of: "\(suffix)$", with: "", options: .regularExpression)
        }
    }

    // Convert PascalCase to separate words
    name = name.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)

    return name
}

func openPreferencePane(at path: String) {
    let url = URL(fileURLWithPath: path)
    NSWorkspace.shared.open(url)
}

public class SystemPreferencePanesExtension: PenguinExtension {
    public let identifier = "com.penguin.system_prefs"
    public let name = "System Preference Panes"

    var commands: [Command] = []

    init() {
        commands = listPreferencePanes().map { (name, path) in
            Command(
                id: generateCommandId(extensionId: "", commandTitle: name),
                title: "System: \(name)",
                subtitle: "Open System Preferences",
                icon: NSImage(systemSymbolName: "gear", accessibilityDescription: "System Preferences"),
                action: {
                    Penguin.shared.hideMainWindow()
                    openPreferencePane(at: path)
                    return nil
                }
            )
        }
    }

    public func getCommands() -> [Command] {
        commands
    }
}
