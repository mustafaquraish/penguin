import Cocoa
import SwiftUI
import KeyboardShortcuts

struct GlobalSearchView: View {
    // TODO: We should store the last access times of each known command and sort the commands
    //       by the last access time.
    let items: [Command] = ExtensionManager.shared.getAllCommands()
    let onItemSelected: (Command) -> Void

    var body: some View {
        SearchableView(
            items: items,
            fuzzyMatchKey: { item in item.title },
            onItemSelected: onItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            ScrollingSelectionList(
                items: filteredItems,
                focusedIndex: focusedIndex,
                onItemClicked: onItemSelected,
                onItemSelected: onItemSelected,
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
