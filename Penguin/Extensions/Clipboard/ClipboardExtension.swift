import Cocoa
import SwiftUI

struct ClipboardView: View {
    let clip = ClipboardManager.shared

    func onItemSelected(_ item: ClipboardItem) {
        print("Pasting \(item) into application")
        clip.closeMainWindowAndPasteItemIntoApplication(item: item)
    }

    var body: some View {
        FuzzySearchableView(
            items: clip.getItems(),
            fuzzyMatchKey: { item in 
                if item.contentType == .text {
                    return item.text!
                } else {
                    return item.previewText
                }
            },
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
                            String(item.previewText)
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

                            if current.contentType == .image {
                                if let img = current.loadImage() {
                                    Image(nsImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    Text("Error loading image")
                                }
                            } else {
                                ScrollView {
                                    Text(current.text!)
                                        .font(.system(size: 12, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
// !                                        .padding(3)
                                        .textSelection(.enabled)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .padding(3)
                            }
                            Spacer()
                            Divider()
                            HStack {
                                Text("Time: \(current.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                Spacer()
                                Text("Size: \(current.sizeBytes) bytes")
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
                .padding(.trailing, 15)
            }
        }
    }
}

struct ClipboardSettingsView: View {
    @State private var maxItems: Int
    @State private var refreshTime: Double

    init() {
        self.maxItems = ClipboardManager.shared.maxItems
        self.refreshTime = ClipboardManager.shared.refreshTime
    }

    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        return formatter
    }()

    var body: some View {
        Form {
            Labelled(label: "Max Items") {
                TextField("", value: $maxItems, formatter: numberFormatter)
                    .frame(maxWidth: 100)
                    .onChange(of: maxItems) { _, newValue in
                        ClipboardManager.shared.maxItems = newValue
                    }
            }

            Labelled(label: "Polling time (s)") {
                TextField("", value: $refreshTime, formatter: numberFormatter)
                    .frame(maxWidth: 100)
                    .onChange(of: refreshTime) { _, newValue in
                        ClipboardManager.shared.updateRefreshTime(newRefreshTime: newValue)
                    }
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
            makeCommand(
                title: "Clipboard Manager",
                subtitle: "Open clipboard manager",
                icon: NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Clipboard"),
                action: {
                    ClipboardView()
                },
                settingsView: {
                    ClipboardSettingsView()
                }
            )
        ]
    }

    public func getCommands() -> [Command] {
        commands
    }
}

