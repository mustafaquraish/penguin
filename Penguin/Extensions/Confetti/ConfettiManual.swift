import Cocoa

func showConfetti() {
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

        _ = ConfettiController(window: window)

        // Create confetti view as content
        let confettiView =
            CornerConfettiView(frame: window.contentView?.bounds ?? .zero)

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

class ConfettiController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @objc func cancel(_ sender: Any?) {
        close()
    }
}


class CornerConfettiView: NSView {
    private var emitterLayers: [CAEmitterLayer] = []
    private var active = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = false
        setupEmitterLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = false
        setupEmitterLayers()
    }

    private func setupEmitterLayers() {
        // Create an emitter for each corner
        for _ in 0..<4 {
            let emitter = CAEmitterLayer()
            emitter.emitterShape = .point
            emitter.emitterSize = CGSize(width: 10, height: 10)
            emitter.renderMode = .oldestFirst
            emitter.birthRate = 0
            layer?.addSublayer(emitter)
            emitterLayers.append(emitter)
        }
    }

    override func layout() {
        super.layout()
        updateEmitterPositions()
    }

    private func updateEmitterPositions() {
        guard emitterLayers.count >= 4 else { return }

        // Position emitters slightly inset from corners
        let inset: CGFloat = 20

        // Bottom left
        emitterLayers[0].emitterPosition = CGPoint(x: inset, y: inset)

        // Bottom right
        emitterLayers[1].emitterPosition = CGPoint(x: bounds.width - inset, y: inset)
    }

    func startConfetti() {
        guard !active else { return }
        active = true

        // Generate cells on background thread
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            // Generate different cell configurations for each corner
            let bottomLeftCells = self.generateEmitterCells(angle: +CGFloat.pi/4) // -45 degrees (up-right)
            let bottomRightCells = self.generateEmitterCells(angle: +3*CGFloat.pi/4) // -135 degrees (up-left)

            DispatchQueue.main.async {
                self.updateEmitterPositions()

                // Configure each corner emitter
                if self.emitterLayers.count >= 2 {
                    self.emitterLayers[0].emitterCells = bottomLeftCells
                    self.emitterLayers[1].emitterCells = bottomRightCells

                    // Start emission
                    for layer in self.emitterLayers {
                        layer.birthRate = 1
                    }
                }

                // Stop after 4 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stopConfetti()
                }
            }
        }
    }

    func stopConfetti() {
        for emitter in emitterLayers {
            emitter.birthRate = 0
        }
        active = false
    }

    private func generateEmitterCells(angle: CGFloat) -> [CAEmitterCell] {
        let colors: [NSColor] = [
            .systemRed, .systemBlue, .systemGreen,
            .systemYellow, .systemPurple, .systemOrange
        ]

        var cells: [CAEmitterCell] = []

        for color in colors {
            cells.append(confettiCell(color: color, shape: .square, angle: angle))
            cells.append(confettiCell(color: color, shape: .circle, angle: angle))
        }

        return cells
    }

    private enum ConfettiShape {
        case circle
        case square
    }

    private func confettiCell(color: NSColor, shape: ConfettiShape, angle: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 15
        cell.lifetime = 4
        cell.lifetimeRange = 1.5
        cell.velocity = 300
        cell.velocityRange = 100
        cell.spin = 4
        cell.spinRange = 2
        cell.scaleRange = 0.25
        cell.scaleSpeed = -0.1

        // Set emission direction and spread
        cell.emissionLongitude = angle  // Direction
        cell.emissionRange = CGFloat.pi / 8  // Cone width (22.5 degrees)

        // Content and physics
        cell.contents = confettiImage(color: color, shape: shape)
        cell.yAcceleration = -50
        cell.xAcceleration = 0

        return cell
    }

    private func confettiImage(color: NSColor, shape: ConfettiShape) -> CGImage? {
        let size = CGSize(width: 8, height: 8)
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
