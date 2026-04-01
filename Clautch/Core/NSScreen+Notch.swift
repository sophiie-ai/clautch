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

    /// A window frame for the Dynamic-Island-style panel that extends
    /// below the notch. The panel is wider than the notch and drops down
    /// so creatures can walk inside the expanded black area.
    var notchWindowFrame: NSRect? {
        guard let notch = notchFrame else { return nil }

        // The panel extends sideways and downward from the notch.
        let sideExtension: CGFloat = 80   // extra width beyond notch on each side
        let dropHeight: CGFloat = 160     // max drop below the notch when expanded

        return NSRect(
            x: notch.origin.x - sideExtension,
            y: notch.origin.y - dropHeight,
            width: notch.width + sideExtension * 2,
            height: notch.height + dropHeight
        )
    }
}
