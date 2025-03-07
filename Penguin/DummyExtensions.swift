import SwiftUI

public class FruitExtension: PenguinExtension {
    public let identifier = "com.penguin.fruit"
    public let name = "Fruit"

    var fruits: [String] = []

    init() {
        fruits = [
            "Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple",
        ]
    }

    // func search(query: String) -> [Command]
    public func getCommands() -> [Command] {
        fruits.map { fruit in
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: fruit,
                subtitle: "A fruit",
                action: {
                    print("Selected fruit: \(fruit)")
                    return nil
                }
            )
        }
    }
}

public class TwoPanelExtension: PenguinExtension {
    public let identifier = "com.penguin.two-panel"
    public let name = "Two Panel"

    public func getCommands() -> [Command] {
        return [
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: "Two Panel",
                subtitle: "Two Panel",
                action: {
                    return ContentView()
                }
            )
        ]
    }
}

extension NumberFormatter {
    static let spelled: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter
    }()
}
extension Numeric {
    var spelledOut: String? { NumberFormatter.spelled.string(for: self) }
}

public class NavigationPanelExtension: PenguinExtension {
    public let identifier = "com.penguin.navigation-panel"
    public let name = "Navigation Panel"

    public func getCommands() -> [Command] {
        return [
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: "Navigation Panel",
                subtitle: "Navigation Panel",
                action: {
                    NavigationView {
                        VStack {
                            List(0..<100) { index in
                                Text("Item \(index.spelledOut ?? "unknown")")
                            }
                        }
                        .navigationTitle("Navigation Panel")
                    }
                    .frame(minWidth: 300, minHeight: 400)
                    .navigationViewStyle(DefaultNavigationViewStyle())
                }
            )
        ]
    }
}
