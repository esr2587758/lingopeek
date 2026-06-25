import AppKit
import SwiftUI

@MainActor
enum SettingsSnapshotRenderer {
    static func render(to url: URL) throws {
        let size = NSSize(width: 760, height: 680)
        let hostingView = NSHostingView(rootView: SettingsView())
        hostingView.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentView = hostingView
        window.layoutIfNeeded()
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.couldNotCreateBitmap
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.couldNotEncodePNG
        }
        try data.write(to: url, options: .atomic)
    }

    enum SnapshotError: Error {
        case couldNotCreateBitmap
        case couldNotEncodePNG
    }
}
