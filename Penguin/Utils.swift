import AppKit

func imageFromEmoji(emoji: String, width: Int, height: Int) -> NSImage {
    // Use penguin emoji as a fallback
    let image = NSImage(
        size: NSSize(width: width, height: height),
        flipped: false,
        drawingHandler: { (rect) in
            emoji.draw(in: rect)
            return true
        }
    )
    return image
}

func resizeImage(image: NSImage, width: Int, height: Int) -> NSImage {
    let newImage = NSImage(
        size: NSSize(width: width, height: height),
        flipped: false,
        drawingHandler: { (rect) in
            image.draw(in: rect)
            return true
        }
    )
    return newImage
}


func loadImage(named name: String) -> NSImage? {
#if SWIFT_PACKAGE
    guard let url = Bundle.module.url(forResource: name, withExtension: "png") else {
        print("oh :(")
        return nil
    }
    return NSImage(contentsOf: url)
#else
    return NSImage(named: name)
#endif
}