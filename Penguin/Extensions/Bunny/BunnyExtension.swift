import SwiftUI
import Foundation

// MARK: - Data Models

struct BunnyResponse: Codable {
    let items: [BunnyItem]
}

struct BunnyItem: Codable {
    let title: String
    let subtitle: String?
    let arg: String
    let valid: Bool
    let type: String
}

// MARK: - Executable Runner

enum ExecutableError: Error {
    case executionFailed(String)
    case jsonParsingFailed(Error)
}

func runExecutableAndParseJSON(executablePath: String, argument: String) throws -> BunnyResponse {
    let process = Process()
    let outputPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = [argument]
    process.standardOutput = outputPipe
    process.standardError = nil  // Suppress errors from interfering
    process.qualityOfService = .userInitiated // Prevent UI lag

    try process.run()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    return try JSONDecoder().decode(BunnyResponse.self, from: outputData)
}

struct BunnyView: View {
    private func dummyBunnyItem(title: String) -> BunnyItem {
        BunnyItem(
            title: title,
            subtitle: "Command for \(title)",
            arg: title,
            valid: true,
            type: "default"
        )
    }

    func fetchBunnyCommands(_ text: String) -> [BunnyItem] {
        print("Calling bunny with text: \(text)")

        guard let executablePath = BunnySettings.exec_path else {
            return [
                dummyBunnyItem(title: "Error: Bunny executable path not set")
            ]
        }
        let argument = text

        do {
            let response = try runExecutableAndParseJSON(executablePath: executablePath, argument: argument)
            return response.items
        } catch {
            print("Error running executable: \(error)")
            return [
                dummyBunnyItem(title: "Error: \(error)")
            ]
        }
    }

    // Modified handler to record command usage
    private func handleItemSelected(_ item: BunnyItem) {
        onItemSelected(item)
    }

    private func onItemSelected(_ item: BunnyItem) {
        Penguin.shared.hideMainWindow()
        print("Bunny: selected item: \(item.title)")
        // `arg` is a URL, open it
        if let url = URL(string: item.arg) {
            NSWorkspace.shared.open(url)
        }
    }

    var body: some View {
        ExternalSearchableView(
            performSearch: fetchBunnyCommands,
            onItemSelected: handleItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            ScrollingSelectionList(
                items: filteredItems,
                focusedIndex: focusedIndex,
                onItemClicked: handleItemSelected,
                onItemSelected: handleItemSelected,
                elem: { item in
                    HStack(spacing: 8) {
                        Text(item.title)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundColor(.gray.opacity(0.5))
                        } else {
                            EmptyView()
                        }
                    }
                }
            )
        }
    }
}

struct BunnySettings {
    @UserDefault<String?>(key: "bunny.exec_path", defaultValue: nil)
    static public var exec_path: String?
}

struct BunnySettingsView: View {
    @State private var execPath: String = BunnySettings.exec_path ?? ""

    var body: some View {
        VStack {
            Labelled(label: "Executable") {
                TextField("", text: $execPath)
                    .padding()
                    .onChange(of: execPath) { _, newValue in
                        BunnySettings.exec_path = newValue
                }
            }
        }
    }
}

public class BunnyExtension: PenguinExtension {
    public let identifier = "com.penguin.bunny"
    public let name = "Bunny"

    var commands: [Command] = []

    init() {
        commands = [
            makeCommand(
                title: "Bunny",
                subtitle: "Bunnylol extension",
                icon: NSImage(systemSymbolName: "hare", accessibilityDescription: "Clipboard"),
                action: {
                    BunnyView()
                },
                settingsView: {
                    BunnySettingsView()
                }
            )
        ]
    }

    public func getCommands() -> [Command] {
        commands
    }
}

