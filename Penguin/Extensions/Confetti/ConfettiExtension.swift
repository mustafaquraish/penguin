import Cocoa
import SwiftUI

public class ConfettiExtension: PenguinExtension {
    public let identifier = "com.penguin.confetti"
    public let name = "Confetti"
    static public let commandId = "com.penguin.confetti.command"

    var commands: [Command] = []

    init() {
        commands = [
            Command(
                id: ConfettiExtension.commandId,
                title: "Confetti",
                subtitle: "Show Some Confetti",
                icon: imageFromEmoji(emoji: "🎉", width: 20, height: 20),
                action: {
                    Penguin.shared.hideMainWindow()
                    showConfetti()
                    return nil
                }
            )
        ]
    }

    public func getCommands() -> [Command] {
        commands
    }
}
