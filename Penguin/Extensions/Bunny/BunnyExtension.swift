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

// func runBunnyExecutable(path: String, argument: String) throws -> BunnyResponse {
//     // Create process
//     let process = Process()
//     process.executableURL = URL(fileURLWithPath: path)
//     process.arguments = [argument]

//     // Important: Set launch path to prevent focus issues
//     process.launchPath = path

//     // Prevent the process from stealing focus
//     process.qualityOfService = .background

//     // Set process not to launch in a new window
//     process.environment = ["NSRequiresAquaSystemAppearance": "NO"]

//     // Set up pipes for output
//     let outputPipe = Pipe()
//     process.standardOutput = outputPipe

//     let errorPipe = Pipe()
//     process.standardError = errorPipe

//     // Store the current app that has focus
//     let currentApp = NSWorkspace.shared.frontmostApplication

//     // Run the process
//     do {
//         try process.run()
//         process.waitUntilExit()
//     } catch {
//         throw ExecutableError.executionFailed("Failed to execute process: \(error.localizedDescription)")
//     }

//     // Restore focus to the original application
//     if let currentApp = currentApp {
//         DispatchQueue.main.async {
//             if let bundleURL = currentApp.bundleURL {
//                 NSWorkspace.shared.open(bundleURL)
//             }
//         }
//     }

//     // Check if process exited successfully
//     if process.terminationStatus != 0 {
//         let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
//         let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
//         throw ExecutableError.executionFailed("Process failed with status \(process.terminationStatus): \(errorMessage)")
//     }

//     // Get output data
//     let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

//     // Parse JSON
//     do {
//         let decoder = JSONDecoder()
//         return try decoder.decode(BunnyResponse.self, from: outputData)
//     } catch {
//         print("JSON parsing error: \(error)")
//         print("Raw output: \(String(data: outputData, encoding: .utf8) ?? "Unable to convert output to string")")
//         throw ExecutableError.jsonParsingFailed(error)
//     }
// }

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
        print("Selected item: \(item.title)")
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

