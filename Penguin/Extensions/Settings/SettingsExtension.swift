import Cocoa
import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    // TODO: Add a "dummy" command or some other way to configure the settings of
    //       the whole application. Currently, we can only configure the settings
    //       of the different commands.
    //       Perhaps also extension-specific settings, not only command-specific.
    let items: [Command]

    func onItemSelected(_ item: Command) {
        print("selected item: \(item)")
    }


    var body: some View {
        SearchableView(
            items: items,
            fuzzyMatchKey: { item in item.title },
            onItemSelected: onItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            HStack {
                ScrollingSelectionList(
                    items: filteredItems,
                    focusedIndex: focusedIndex,
                    onItemClicked: onItemSelected,
                    onItemSelected: onItemSelected,
                    elem: { item in
                        HStack(spacing: 8) {
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

                            } else {
                                Text("No additional settings")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Divider()
                            Text("Extension: \(selectedItem.extensionName) (\(selectedItem.extensionId))")
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

extension KeyboardShortcuts.Name {
    static let penguinSettings = KeyboardShortcuts.Name("com.penguin.settings")
}

public class SettingsExtension: PenguinExtension {
    public let identifier = "com.penguin.settings"
    public let name = "Settings"

    var commands: [Command] = []

    init() {
        commands = [
            Command(
                extensionId: identifier,
                extensionName: name,
                title: "Settings",
                subtitle: "Open settings",
                icon: NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings"),
                shortcutName: .penguinSettings,
                action: {
                    SettingsView(
                        items: ExtensionManager.shared
                            .getAllCommands()
                            .filter { $0.shortcutName != .penguinSettings }
                    )
                }
            )
        ]
    }

    public func getCommands() -> [Command] {
        commands
    }
}