import Cocoa
import KeyboardShortcuts
import SwiftUI

struct PreferencesView: View {
    private static var dummyApplicationSettingsCommand: Command = Command(
        id: KeyboardShortcuts.Name.togglePenguinWindow.rawValue,
        title: "Penguin",
        subtitle: "General Preferences",
        icon: Penguin.penguinIcon,
        action: { nil },  // This command is not used, it's just a placeholder
        settingsView: { GeneralPenguinPreferencesView() }
    )

    var items: [Command] {
        return [PreferencesView.dummyApplicationSettingsCommand]
            + ExtensionManager.shared.getAllCommands().filter {
                $0.id != PreferencesExtension.commandId
            }
    }

    var body: some View {
        SearchableView(
            items: items,
            fuzzyMatchKey: { item in item.title },
            onItemSelected: { _ in }
        ) { filteredItems, selectedItem, focusedIndex in
            HStack {
                ScrollingSelectionList(
                    items: filteredItems,
                    focusedIndex: focusedIndex,
                    onItemClicked: { _ in },
                    onItemSelected: { _ in },
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
                            Spacer()
                            KeyboardShortcuts.Recorder(for: item.shortcutName)
                        }
                    }
                )

                Divider()

                HStack {
                    if let selectedItem = selectedItem {
                        VStack {
                            // Top: Title and subtitle for the selected item
                            Text(selectedItem.title)
                                .font(.headline)
                                .padding(20)

                            Text(selectedItem.subtitle ?? "")
                                .font(.body)
                                .foregroundColor(.gray)

                            Spacer()
                            // Right side: Details for the selected item
                            if let settingsView = selectedItem.settingsView() {
                                AnyView(settingsView)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 20)

                            } else {
                                Text("No additional settings")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Divider()
                            Text(
                                "Command ID: \(selectedItem.id)"
                            )
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                        }
                    } else {
                        EmptyView()
                    }
                }
                .frame(maxWidth: 400)
            }
        }
    }
}

struct GeneralPenguinPreferencesView: View {
    var body: some View {
        VStack {
            Text("No additional settings (yet)")
            Text("Change the Penguin hotkey on the left")
        }
    }
}

public class PreferencesExtension: PenguinExtension {
    public let identifier = "com.penguin.preferences"
    public let name = "Preferences"
    static public let commandId = "com.penguin.preferences.command"

    var commands: [Command] = []

    init() {
        commands = [
            Command(
                id: PreferencesExtension.commandId,
                title: "Preferences",
                subtitle: "Open preferences",
                icon: Penguin.penguinIcon,
                action: {
                    PreferencesView()
                }
            )
        ]
    }

    public func getCommands() -> [Command] {
        commands
    }
}
