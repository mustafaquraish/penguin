import AppKit
import QuartzCore

// Global variables to manage the confetti window and emitter
var confettiWindow: NSWindow?
var emitterLayer: CAEmitterLayer?

// Helper functions to create shape images
func createSquareImage(size: Int) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
    context.setFillColor(NSColor.white.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    return context.makeImage()
}

func createCircleImage(size: Int) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
    context.setFillColor(NSColor.white.cgColor)
    context.addEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
    context.fillPath()
    return context.makeImage()
}

func createTriangleImage(size: Int) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
    context.setFillColor(NSColor.white.cgColor)
    context.move(to: CGPoint(x: size / 2, y: 0))
    context.addLine(to: CGPoint(x: size, y: size))
    context.addLine(to: CGPoint(x: 0, y: size))
    context.closePath()
    context.fillPath()
    return context.makeImage()
}

/**
 Displays a burst of confetti with random shapes (square, circle, triangle) and simulated 3D rotation.
 */
func showConfetti() {
    // Set up the confetti window if it doesn’t exist
    if confettiWindow == nil {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        confettiWindow = NSWindow(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
        confettiWindow?.backgroundColor = .clear
        confettiWindow?.isOpaque = false
        confettiWindow?.ignoresMouseEvents = true
        confettiWindow?.level = .floating
        confettiWindow?.hasShadow = false
        confettiWindow?.contentView?.wantsLayer = true

        // Initialize the emitter layer
        emitterLayer = CAEmitterLayer()
        emitterLayer?.emitterPosition = CGPoint(x: screenFrame.width / 2, y: screenFrame.height)
        emitterLayer?.emitterSize = CGSize(width: screenFrame.width, height: -30)
        emitterLayer?.emitterShape = .line


        // Define colors and shapes
        let colors: [NSColor] = [.red, .green, .blue, .yellow]
        let shapes: [CGImage?] = [
            createSquareImage(size: 10),
            createCircleImage(size: 10),
            createTriangleImage(size: 10)
        ]

        // Create emitter cells for each color-shape combination
        var emitterCells: [CAEmitterCell] = []
        for color in colors {
            for shape in shapes {
                guard let shapeImage = shape else { continue }
                let cell = CAEmitterCell()
                cell.contents = shapeImage // Assign the shape image
                cell.color = color.cgColor
                cell.birthRate = 30 // Spread total birth rate across shapes
                cell.lifetime = 5.0
                cell.velocity = 200
                cell.velocityRange = 50
                cell.emissionLongitude = -CGFloat.pi // Upward direction
                cell.emissionRange = CGFloat.pi / 4 // Spread angle
                cell.yAcceleration = -200 // Gravity effect
                cell.scale = 1.5
                cell.spin = 2 // Base spin around z-axis
                cell.spinRange = 4 // Random spin variation
                emitterCells.append(cell)
            }
        }
        emitterLayer?.emitterCells = emitterCells
        confettiWindow?.contentView?.layer?.addSublayer(emitterLayer!)
    }

    // Display the confetti burst
    confettiWindow?.makeKeyAndOrderFront(nil)

    // Short burst effect
    emitterLayer?.birthRate = 1
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        emitterLayer?.birthRate = 0
    }
}
