import AppKit
import SwiftUI

struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DraggableHandleView {
        DraggableHandleView()
    }

    func updateNSView(_ nsView: DraggableHandleView, context: Context) {}
}

final class DraggableHandleView: NSView {
    override var mouseDownCanMoveWindow: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
