import Cocoa
import SwiftUI
import ConfettiSwiftUI

// FIXME: This lags really hard when running in the app
//        Maybe just look into how it works and steal the code to work with `Manual` instead
func showConfettiNew() {
    let contentView = ConfettiUIView(frame: NSScreen.main?.frame ?? .zero)
    let hostingView = NSHostingView(rootView: contentView)

    DispatchQueue.main.async {
        // Create window instance
        let window = NSPanel(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure window properties
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = hostingView

        window.orderFront(nil)
        // Show window

        // Auto close after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 2.0
                window.animator().alphaValue = 0
            } completionHandler: {
                window.close()
            }
        }
    }
}

struct ConfettiUIView: View {
    let frame: NSRect
    @State var trigger: Int = 0

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("")
                    .confettiCannon(
                        trigger: $trigger,
                        num: 150,
                        opacity: 0.8,
                        openingAngle: Angle(degrees: 20),
                        closingAngle: Angle(degrees: 80),
                        radius: 1400,
                        repetitionInterval: 0.0
                    )
                Spacer()
                Text("")
                    .confettiCannon(
                        trigger: $trigger,
                        num: 150,
                        opacity: 0.8,
                        openingAngle: Angle(degrees: 100),
                        closingAngle: Angle(degrees: 170),
                        radius: 1400,
                        repetitionInterval: 0.0
                    )
            }
        }
        .onAppear() {
            trigger += 1
        }
    }
}


public class ConfettiExtension: PenguinExtension {
    public let identifier = "com.penguin.confetti"
    public let name = "Confetti"
    static public let commandId = "com.penguin.confetti.command"

    var commands: [Command] = []

    init() {
        commands = [
            Command(
                id: ConfettiExtension.commandId,
                title: "Confetti 🎉",
                subtitle: "Show Some Confetti",
                icon: nil,
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
