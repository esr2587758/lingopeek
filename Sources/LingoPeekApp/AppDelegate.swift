import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: LingobarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["LINGOPEEK_UI_TEST_RESET_SETTINGS"] == "1" {
            AppSettings.resetForUITesting()
        }

        if let snapshotPath = ProcessInfo.processInfo.environment["LINGOPEEK_RENDER_SETTINGS_SNAPSHOT"] {
            renderSettingsSnapshotAndTerminate(snapshotPath)
            return
        }

        let openSettingsOnLaunch = ProcessInfo.processInfo.environment["LINGOPEEK_OPEN_SETTINGS"] == "1"
        let uiTestMode = ProcessInfo.processInfo.environment["LINGOPEEK_UI_TEST_MODE"] == "1"
        NSApp.setActivationPolicy(openSettingsOnLaunch || uiTestMode ? .regular : .accessory)
        controller = LingobarController()
        controller?.start(openSettingsOnLaunch: openSettingsOnLaunch)
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }

    @MainActor
    private func renderSettingsSnapshotAndTerminate(_ snapshotPath: String) {
        NSApp.setActivationPolicy(.prohibited)
        DispatchQueue.main.async {
            do {
                try SettingsSnapshotRenderer.render(to: URL(fileURLWithPath: snapshotPath))
                NSApp.terminate(nil)
            } catch {
                fputs("Failed to render settings snapshot: \(error)\n", stderr)
                exit(1)
            }
        }
    }
}
