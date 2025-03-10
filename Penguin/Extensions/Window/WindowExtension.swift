import Cocoa
import SwiftUI

struct WindowManagerSharedSettings {
    @UserDefault<Float>(key: "windowmanager.almostMaximizePct", defaultValue: 80.0)
    public static var almostMaximizePct: Float
}


struct AlmostMaximizeSettingsView: View {
    @State private var almostMaximizePct: Float = WindowManagerSharedSettings.almostMaximizePct

    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        return formatter
    }()

    var body: some View {
        Form {
            Labelled(label: "Percentage") {
                TextField("", value: $almostMaximizePct, formatter: numberFormatter)
                    .frame(maxWidth: 100)
                    .onChange(of: almostMaximizePct) { _, newValue in
                        WindowManagerSharedSettings.almostMaximizePct = newValue
                    }
            }
        }
    }
}

public class WindowExtension: PenguinExtension {
    public let identifier = "com.penguin.window"
    public let name = "Window"

    let wm = WindowManager.shared

    var commands: [Command] = []

    init() {
        commands = [
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: "Window: Left Half",
                subtitle: "Move window to left half of screen",
                icon: NSImage(
                    systemSymbolName: "rectangle.lefthalf.filled",
                    accessibilityDescription: "Left half"),
                action: {
                    self.wm.moveActiveWindowToLeftHalf()
                    return nil
                }
            ),
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: "Window: Right Half",
                subtitle: "Move window to right half of screen",
                icon: NSImage(
                    systemSymbolName: "rectangle.righthalf.filled",
                    accessibilityDescription: "Right half"),
                action: {
                    self.wm.moveActiveWindowToRightHalf()
                    return nil
                }
            ),
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: "Window: Next Display",
                subtitle: "Move window to next display",
                icon: NSImage(systemSymbolName: "arrow.right.arrow.left", accessibilityDescription: "Next display"), 
                action: {
                    self.wm.cycleActiveWindowAcrossDisplays()
                    return nil
                }
            ),
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: "Window: Maximize",
                subtitle: "Maximize window",
                icon: NSImage(
                    systemSymbolName: "rectangle.fill",
                    accessibilityDescription: "Maximize"),
                action: {
                    self.wm.maximizeActiveWindow()
                    return nil
                }
            ),
            ShortcutCommand(
                extName: name,
                extIdentifier: identifier,
                title: "Window: Almost Maximize",
                subtitle: "Almost maximize window (80% of screen)",
                icon: NSImage(
                    systemSymbolName: "rectangle",
                    accessibilityDescription: "Almost maximize"),
                action: {
                    self.wm.almostMaximizeActiveWindow(
                        pct: WindowManagerSharedSettings.almostMaximizePct
                    )
                    return nil
                },
                settingsView: {
                    AlmostMaximizeSettingsView()
                }
            ),
        ]
    }

    public func getCommands() -> [Command] {
        commands
    }
}
