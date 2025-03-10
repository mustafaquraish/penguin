import Cocoa

public class WindowManager {
    public static let shared = WindowManager()
    let penguin = Penguin.shared

    private var hasAccessibilityPermissions: Bool = false

    public init() {
        checkAccessibilityPermissions()
    }

    /// Checks if the app has accessibility permissions and requests them if not
    private func checkAccessibilityPermissions() {
        // Check if accessibility is enabled
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true] as CFDictionary
        hasAccessibilityPermissions = AXIsProcessTrustedWithOptions(options)

        if hasAccessibilityPermissions {
            print("Accessibility permissions granted")
        } else {
            print("Accessibility permissions needed - requested")
        }
    }

    /// Moves the currently active application window to the left half of the screen
    public func moveActiveWindowToLeftHalf() {
        print("Attempting to move window to left half")
        guard hasAccessibilityPermissions else {
            print("No accessibility permissions to move windows")
            checkAccessibilityPermissions()
            return
        }

        guard let screen = NSScreen.main,
            let window = getCurrentFocusedWindow()
        else {
            print("Could not get active window or screen")
            return
        }

        let screenFrame = screen.visibleFrame
        let newFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: screenFrame.width / 2,
            height: screenFrame.height
        )

        setWindowFrame(window, to: newFrame)
        print("Window moved to left half")
    }

    /// Moves the currently active application window to the right half of the screen
    public func moveActiveWindowToRightHalf() {
        print("Attempting to move window to right half")
        guard hasAccessibilityPermissions else {
            print("No accessibility permissions to move windows")
            checkAccessibilityPermissions()
            return
        }

        guard let screen = NSScreen.main,
            let window = getCurrentFocusedWindow()
        else {
            print("Could not get active window or screen")
            return
        }

        let screenFrame = screen.visibleFrame
        let newFrame = NSRect(
            x: screenFrame.origin.x + screenFrame.width / 2,
            y: screenFrame.origin.y,
            width: screenFrame.width / 2,
            height: screenFrame.height
        )

        setWindowFrame(window, to: newFrame)
        print("Window moved to right half")
    }

    /// Maximizes the currently active application window
    public func maximizeActiveWindow() {
        print("Attempting to maximize window")
        guard hasAccessibilityPermissions else {
            print("No accessibility permissions to move windows")
            checkAccessibilityPermissions()
            return
        }

        guard let screen = NSScreen.main,
            let window = getCurrentFocusedWindow()
        else {
            print("Could not get active window or screen")
            return
        }

        let screenFrame = screen.visibleFrame

        setWindowFrame(window, to: screenFrame)
        print("Window maximized")
    }

    public func almostMaximizeActiveWindow(pct: Float) {
        guard hasAccessibilityPermissions else {
            print("No accessibility permissions to move windows")
            checkAccessibilityPermissions()
            return
        }

        guard let window = getCurrentFocusedWindow() else {
            print("No focused window")
            return
        }

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero

        let newFrameWidth = screenFrame.width * CGFloat(pct)
        let newFrameHeight = screenFrame.height * CGFloat(pct)

        let newFrame = NSRect(
            x: screenFrame.origin.x + (screenFrame.width - newFrameWidth) / 2,
            y: screenFrame.origin.y + (screenFrame.height - newFrameHeight) / 2,
            width: newFrameWidth,
            height: newFrameHeight
        )

        setWindowFrame(window, to: newFrame)
        print("Window almost maximized to \(pct)%")
    }

    /// Moves the currently active application window to the next display
    /// and maximizes it on that display
    public func cycleActiveWindowAcrossDisplays() {
        // From Claude 3.7... blame it if it doesn't work.

        guard hasAccessibilityPermissions else {
            print("No accessibility permissions to move windows")
            checkAccessibilityPermissions()
            return
        }

        guard let window = getCurrentFocusedWindow() else {
            print("No focused window")
            return
        }

        // Get all screens
        let screens = NSScreen.screens
        guard screens.count > 1 else {
            print("Only one display detected, nothing to cycle to")
            return
        }

        // Get current window position and size
        var windowPos = CGPoint.zero
        var windowSize = CGSize.zero

        // Fix: Use CFTypeRef? instead of AXValue?
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        let posError = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        let sizeError = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)

        if posError != .success || sizeError != .success {
            print("Could not get window position or size")
            return
        }

        // Cast to AXValue and extract values
        guard let positionValue = positionRef as! AXValue?,
            let sizeValue = sizeRef as! AXValue? else {
            print("Failed to cast position or size values")
            return
        }

        AXValueGetValue(positionValue, .cgPoint, &windowPos)
        AXValueGetValue(sizeValue, .cgSize, &windowSize)

        print("Window position: \(windowPos)")
        print("Window size: \(windowSize)")

        // Simple screen detection: find which screen the top-left of the window is on
        var currentScreenIndex = -1
        var closestDistance = CGFloat.greatestFiniteMagnitude

        for (index, screen) in screens.enumerated() {
            print("Checking screen: \(index) with frame: \(screen.frame)")

            // Calculate distance from window top-left to screen origin
            let xDistance = abs(windowPos.x - screen.frame.minX)
            let yDistance = abs(windowPos.y - screen.frame.minY)
            let distance = sqrt(xDistance * xDistance + yDistance * yDistance)

            // If window top-left matches exactly with screen origin, we've found our screen
            if windowPos.x == screen.frame.minX && windowPos.y == screen.frame.minY {
                currentScreenIndex = index
                break
            }

            // Otherwise, track closest screen by coordinate distance
            if distance < closestDistance {
                closestDistance = distance
                currentScreenIndex = index
            }
        }

        if currentScreenIndex == -1 {
            print("Could not determine which screen the window is on")
            return
        }

        print("Window is on screen \(currentScreenIndex) (detection by closest screen origin)")

        // Calculate the next screen index (cycle back to first screen if needed)
        let nextScreenIndex = (currentScreenIndex + 1) % screens.count
        let nextScreen = screens[nextScreenIndex]

        // Get the next screen's visible frame (accounting for menu bar, dock, etc.)
        let nextVisibleFrame = nextScreen.visibleFrame

        // Move window to next screen and maximize it
        setWindowFrame(window, to: nextVisibleFrame)
        print("Window moved to screen \(nextScreenIndex + 1) of \(screens.count) and maximized")
    }
    // MARK: - Private Helpers

    private func getCurrentFocusedWindow() -> AXUIElement? {
        guard var app = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost application")
            return nil
        }

        if penguin.window?.isVisible == true {
            if let prev_app = penguin.previousActiveApp {
                app = prev_app
            }
        }

        print("Getting focused window for app: \(app.localizedName ?? "Unknown")")
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var focusedWindow: CFTypeRef?

        let error = AXUIElementCopyAttributeValue(
            appRef, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        if error != .success {
            print("Error getting focused window: \(error)")
            return nil
        }

        return focusedWindow as! AXUIElement?
    }

    private func setWindowFrame(_ window: AXUIElement, to frame: NSRect) {
        // Set position
        var point = CGPoint(x: frame.origin.x, y: frame.origin.y)
        let position = AXValueCreate(AXValueType.cgPoint, &point)
        let positionError = AXUIElementSetAttributeValue(
            window, kAXPositionAttribute as CFString, position!)
        if positionError != .success {
            print("Error setting window position: \(positionError)")
        }

        // Set size
        var size = CGSize(width: frame.width, height: frame.height)
        let sizeValue = AXValueCreate(AXValueType.cgSize, &size)
        let sizeError = AXUIElementSetAttributeValue(
            window, kAXSizeAttribute as CFString, sizeValue!)
        if sizeError != .success {
            print("Error setting window size: \(sizeError)")
        }
    }
}
