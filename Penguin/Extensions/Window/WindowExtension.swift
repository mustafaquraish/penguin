import Cocoa

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
                icon: NSImage(
                    systemSymbolName: "arrow.right.to.line.alt.fill",
                    accessibilityDescription: "Next display"),
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
                    systemSymbolName: "arrow.up.to.line.alt.fill",
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
                    systemSymbolName: "arrow.up.to.line.alt.fill",
                    accessibilityDescription: "Almost maximize"),
                action: {
                    self.wm.almostMaximizeActiveWindow(pct: 0.8)
                    return nil
                }
            ),
        ]
    }

    public func getCommands() -> [Command] {
        commands
    }
}
