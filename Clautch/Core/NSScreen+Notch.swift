import AppKit

extension NSScreen {

    /// Whether this screen is the built-in display (MacBook lid screen).
    var isBuiltIn: Bool {
        guard let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return false
        }
        return CGDisplayIsBuiltin(id) != 0
    }

    /// Whether this screen has a physical notch (MacBook Pro 2021+, MacBook Air 2022+).
    /// Checks safeAreaInsets first (reliable when primary), then auxiliaryTopLeftArea
    /// (works even when the built-in display is not the primary screen).
    var hasNotch: Bool {
        safeAreaInsets.top > 0 || auxiliaryTopLeftArea != nil
    }

    private var notchBarHeight: CGFloat? {
        if safeAreaInsets.top > 0 { return safeAreaInsets.top }
        if let left = auxiliaryTopLeftArea, left.height > 0 { return left.height }
        return nil
    }

    /// The effective notch/panel height — real notch bar on notch screens, 24pt on non-notch.
    var effectiveNotchHeight: CGFloat {
        notchBarHeight ?? 24
    }

    var notchSize: NSSize? {
        guard hasNotch else { return nil }
        guard let left = auxiliaryTopLeftArea,
              let right = auxiliaryTopRightArea,
              let height = notchBarHeight else { return nil }
        let width = right.minX - left.maxX
        guard width > 0, height > 0 else { return nil }
        return NSSize(width: width, height: height)
    }

    /// The frame of the notch in global screen coordinates (nil on non-notch screens).
    /// The notch is physically centered on the display, so we derive position from
    /// the screen frame rather than auxiliaryTopLeftArea (whose coordinate space
    /// varies between primary and non-primary screens).
    var notchFrame: NSRect? {
        guard hasNotch else { return nil }
        guard let size = notchSize else { return nil }
        let x = frame.origin.x + (frame.width - size.width) / 2
        let y = frame.origin.y + frame.height - size.height
        return NSRect(origin: NSPoint(x: x, y: y), size: size)
    }

    /// Synthesized notch-like frame for non-notch screens, centered at the top.
    private var virtualNotchFrame: NSRect {
        let virtualWidth: CGFloat = 200
        let virtualHeight: CGFloat = 24
        let x = frame.origin.x + (frame.width - virtualWidth) / 2
        let y = frame.origin.y + frame.height - virtualHeight
        return NSRect(x: x, y: y, width: virtualWidth, height: virtualHeight)
    }

    /// The effective notch frame — real on notch screens, virtual on non-notch.
    var effectiveNotchFrame: NSRect {
        notchFrame ?? virtualNotchFrame
    }

    /// The effective notch size — real on notch screens, virtual on non-notch.
    var effectiveNotchSize: NSSize {
        notchSize ?? NSSize(width: 200, height: 24)
    }

    /// A window frame for the Dynamic-Island-style panel that extends
    /// below the notch. Works on both notch and non-notch screens.
    var notchWindowFrame: NSRect? {
        let notch = effectiveNotchFrame

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
