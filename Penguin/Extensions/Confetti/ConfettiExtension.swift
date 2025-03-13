import Cocoa

func showConfetti() {
    // Perform UI setup on main thread, but don't block it
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
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Create confetti view as content
        let confettiView = ConfettiView(frame: window.contentView?.bounds ?? .zero)
        confettiView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(confettiView)

        // Show window
        window.orderFront(nil)

        // Start animation
        confettiView.startConfetti()

        // Auto close after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            window.close()
        }
    }
}

class ConfettiView: NSView {
    private let emitterLayer = CAEmitterLayer()
    private var active = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = false
        setupEmitterLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = false
        setupEmitterLayer()
    }

    private func setupEmitterLayer() {
        emitterLayer.emitterPosition = CGPoint(x: bounds.width / 2, y: 0)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
        emitterLayer.renderMode = .oldestFirst
        emitterLayer.birthRate = 0
        layer?.addSublayer(emitterLayer)
    }

    override func layout() {
        super.layout()
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.width / 2, y: 0)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
    }

    func startConfetti() {
        guard !active else { return }
        active = true

        // Generate cells on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cells = self?.generateEmitterCells() ?? []

            DispatchQueue.main.async {
                guard let self = self else { return }
                self.emitterLayer.emitterCells = cells
                self.emitterLayer.birthRate = 6
            }
        }
    }

    func stopConfetti() {
        emitterLayer.birthRate = 0
        active = false
    }

    private func generateEmitterCells() -> [CAEmitterCell] {
        let colors: [NSColor] = [
            .systemRed, .systemBlue, .systemGreen,
            .systemYellow, .systemPurple, .systemOrange
        ]

        var cells: [CAEmitterCell] = []

        for color in colors {
            cells.append(confettiCell(color: color, shape: .square))
            cells.append(confettiCell(color: color, shape: .circle))
        }

        return cells
    }

    private enum ConfettiShape {
        case circle
        case square
    }

    private func confettiCell(color: NSColor, shape: ConfettiShape) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 4
        cell.lifetime = 10
        cell.velocity = 200
        cell.velocityRange = 50
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 4
        cell.spin = 3.5
        cell.spinRange = 1
        cell.scaleRange = 0.25
        cell.scaleSpeed = -0.1
        cell.contents = confettiImage(color: color, shape: shape)

        // Physics behavior
        cell.yAcceleration = 80
        cell.xAcceleration = 5

        return cell
    }

    private func confettiImage(color: NSColor, shape: ConfettiShape) -> CGImage? {
        let size = CGSize(width: 12, height: 12)
        let image = NSImage(size: size)

        image.lockFocus()
        color.set()

        switch shape {
        case .circle:
            NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        case .square:
            NSRect(origin: .zero, size: size).fill()
        }

        image.unlockFocus()

        var imageRect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
            return nil
        }

        return cgImage
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
