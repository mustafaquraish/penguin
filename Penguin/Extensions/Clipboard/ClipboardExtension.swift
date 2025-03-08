import Cocoa
import SwiftUI

struct ClipboardView: View {
    let clip = ClipboardManager.shared

    func onItemSelected(_ item: ClipboardItem) {
        print("Pasting \(item.text.count) characters")

    }

    var body: some View {
        SearchableView(
            items: clip.getItems(),
            fuzzyMatchKey: { item in item.text },
            onItemSelected: onItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            HStack {
                ScrollingSelectionList(
                    items: filteredItems,
                    focusedIndex: focusedIndex,
                    onItemClicked: { _ in },
                    onItemSelected: onItemSelected,
                    elem: { item in
                        Text(
                            // Only show the first line of the text
                            String(item.text.split(separator: "\n").first ?? item.text[...])
                        )
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    })
                    .frame(maxWidth: 350)

                Divider()

                // Right side: Details for the selected item
                VStack {
                    if let current = selectedItem {
                        VStack {

                            // TODO: It is not possible to copy selected text from this view
                            //       with Cmd+C, because of some weirdness with how we have set up
                            //       the panel/window I am guessing. Looking into it.
                            ScrollView {
                                Text(current.text)
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(3)
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .padding(3)

                            Spacer()
                            Divider()
                            HStack {
                                Text("Time: \(current.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                Spacer()
                                Text("Length: \(current.text.count) characters")
                            }
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(3)
                    } else {
                        Text("Select an item for details")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

public class ClipboardExtension: PenguinExtension {
    public let identifier = "com.penguin.clipboard"
    public let name = "Clipboard"

    var commands: [Command] = []

    init() {
        commands = [
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: "Clipboard Manager",
                subtitle: "Open clipboard manager",
                icon: NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Clipboard"),
                action: {
                    ClipboardView()
                }
            )
        ]
    }

    public func getCommands() -> [Command] {
        commands
    }
}

