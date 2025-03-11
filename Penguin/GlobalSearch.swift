import Cocoa
import SwiftUI
import KeyboardShortcuts

// Command usage tracker to store and manage command usage data
class CommandUsageTracker {
    static let shared = CommandUsageTracker()
    private let defaults = UserDefaults.standard

    static private let lastAccessTimeKey = "command_last_access"
    static private let accessCountKey = "command_access_count"

    // Get the last access time for a command
    func getLastAccessTime(for commandId: String) -> Date {
        let timeDict = defaults.dictionary(forKey: Self.lastAccessTimeKey) as? [String: Double] ?? [:]
        let timestamp = timeDict[commandId] ?? 0
        return Date(timeIntervalSince1970: timestamp)
    }

    // Get the access count for a command
    func getAccessCount(for commandId: String) -> Int {
        let countDict = defaults.dictionary(forKey: Self.accessCountKey) as? [String: Int] ?? [:]
        return countDict[commandId] ?? 0
    }

    // Record command usage
    func recordUsage(for commandId: String) {
        // Update last access time
        var timeDict = defaults.dictionary(forKey: Self.lastAccessTimeKey) as? [String: Double] ?? [:]
        timeDict[commandId] = Date().timeIntervalSince1970
        defaults.set(timeDict, forKey: Self.lastAccessTimeKey)

        // Update access count
        var countDict = defaults.dictionary(forKey: Self.accessCountKey) as? [String: Int] ?? [:]
        countDict[commandId] = (countDict[commandId] ?? 0) + 1
        defaults.set(countDict, forKey: Self.accessCountKey)
    }

    // Calculate a score based on recency and frequency
    func getUsageScore(for commandId: String) -> Double {
        let recency = getLastAccessTime(for: commandId).timeIntervalSince1970
        let frequency = Double(getAccessCount(for: commandId))

        // Combine recency and frequency factors - higher is better
        // This formula can be adjusted to weight recency vs frequency differently
        return recency + (frequency * 1000)
    }
}

struct GlobalSearchView: View {
    // Get all commands and sort them by usage score
    var items: [Command] {
        let allCommands = ExtensionManager.shared.getAllCommands()
        return allCommands.sorted { cmd1, cmd2 in
            // Sort by usage score (descending)
            let score1 = CommandUsageTracker.shared.getUsageScore(for: cmd1.id)
            let score2 = CommandUsageTracker.shared.getUsageScore(for: cmd2.id)
            return score1 > score2
        }
    }

    let onItemSelected: (Command) -> Void

    // Modified handler to record command usage
    private func handleItemSelected(_ command: Command) {
        onItemSelected(command)
        CommandUsageTracker.shared.recordUsage(for: command.id)
    }

    var body: some View {
        SearchableView(
            items: items,
            fuzzyMatchKey: { item in item.title },
            onItemSelected: handleItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            ScrollingSelectionList(
                items: filteredItems,
                focusedIndex: focusedIndex,
                onItemClicked: handleItemSelected,
                onItemSelected: handleItemSelected,
                elem: { item in
                    HStack(spacing: 8) {
                        if let icon = item.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "")
                                .frame(width: 16, height: 16)
                        }
                        Text(item.title)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            // .frame(maxWidth: 200, alignment: .leading)
                        Spacer()
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundColor(.gray.opacity(0.5))
                                // .padding(.leading, 50)
                        } else {
                            EmptyView()
                        }
                    }
                }
            )
        }
    }
}

class GlobalSearchController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @objc func cancel(_ sender: Any?) {
        close()
    }
}
