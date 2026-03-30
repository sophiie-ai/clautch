import AppKit

extension NSScreen {

    /// Whether this screen has a notch (MacBook Pro 2021+, MacBook Air 2022+).
    var hasNotch: Bool {
        safeAreaInsets.top > 0
    }

    /// The size of the notch cutout in screen points.
    var notchSize: NSSize? {
        guard hasNotch else { return nil }
        guard let left = auxiliaryTopLeftArea,
              let right = auxiliaryTopRightArea else { return nil }
        let width = right.minX - left.maxX
        let height = safeAreaInsets.top
        guard width > 0, height > 0 else { return nil }
        return NSSize(width: width, height: height)
    }

    /// The frame of the notch in global screen coordinates.
    var notchFrame: NSRect? {
        guard hasNotch else { return nil }
        guard let left = auxiliaryTopLeftArea,
              let size = notchSize else { return nil }
        let x = frame.origin.x + left.maxX
        let y = frame.origin.y + frame.height - size.height
        return NSRect(origin: NSPoint(x: x, y: y), size: size)
    }

    /// A window frame sized to contain the notch plus a small area below it
    /// where creatures can stand on their grass island.
    var notchWindowFrame: NSRect? {
        guard let notch = notchFrame else { return nil }
        let padding: CGFloat = 30     // horizontal padding
        let grassHeight: CGFloat = 36 // area below notch for grass + creatures
        return NSRect(
            x: notch.origin.x - padding,
            y: notch.origin.y - grassHeight,
            width: notch.width + padding * 2,
            height: notch.height + grassHeight
        )
    }
}
