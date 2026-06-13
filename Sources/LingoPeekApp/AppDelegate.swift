import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: LingobarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller = LingobarController()
        controller?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }
}
