import AppKit
import SwiftUI
import os
import UniformTypeIdentifiers

/// Manages custom background image storage per user.
/// Images are stored in Application Support/Clautch/backgrounds/.
@MainActor
final class CustomBackgroundStore {
    static let shared = CustomBackgroundStore()

    private let logger = Logger(subsystem: "com.clautch.app", category: "CustomBackground")

    /// Recommended dimensions for the background image (matches expanded panel).
    static let recommendedWidth: Int = 400
    static let recommendedHeight: Int = 200

    /// The file URL for the stored custom background.
    private var imageURL: URL? {
        guard let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return nil }
        let dir = support.appendingPathComponent("Clautch/backgrounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom-bg.png")
    }

    /// The cached NSImage, loaded once and kept in memory.
    private var cachedImage: NSImage?
    private var cacheLoaded = false

    /// Load the custom background image, or nil if none is set.
    var image: NSImage? {
        if cacheLoaded { return cachedImage }
        cacheLoaded = true
        guard let url = imageURL, FileManager.default.fileExists(atPath: url.path) else { return nil }
        cachedImage = NSImage(contentsOf: url)
        return cachedImage
    }

    /// Whether a custom background is currently set.
    var hasCustomBackground: Bool { image != nil }

    /// Open a file picker and save the selected image.
    func pickAndSave() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Background Image"
        panel.message = "Recommended size: \(Self.recommendedWidth) x \(Self.recommendedHeight) pixels.\nSupported formats: PNG, JPEG, WebP."
        panel.allowedContentTypes = [.png, .jpeg, .webP]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            NSApp.setActivationPolicy(.accessory)
            return
        }

        save(from: selectedURL)
        NSApp.setActivationPolicy(.accessory)
    }

    /// Save an image from a URL to the custom background location.
    func save(from sourceURL: URL) {
        guard let destURL = imageURL else {
            logger.error("Could not determine background storage path")
            return
        }

        guard let image = NSImage(contentsOf: sourceURL) else {
            logger.error("Could not load image from \(sourceURL.path)")
            return
        }

        // Convert to PNG for consistent storage
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            logger.error("Could not convert image to PNG")
            return
        }

        do {
            try pngData.write(to: destURL)
            cachedImage = image
            cacheLoaded = true
            // Trigger reactive update
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "com.clautch.customBgTimestamp")
            logger.info("Custom background saved: \(destURL.path)")
        } catch {
            logger.error("Failed to save background: \(error)")
        }
    }

    /// Remove the custom background.
    func remove() {
        guard let url = imageURL else { return }
        try? FileManager.default.removeItem(at: url)
        cachedImage = nil
        cacheLoaded = true
        UserDefaults.standard.removeObject(forKey: "com.clautch.customBgTimestamp")
        logger.info("Custom background removed")
    }
}
