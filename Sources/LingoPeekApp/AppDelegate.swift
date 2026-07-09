import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: LingobarController?
    private var appUpdater: AppUpdater?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["LINGOPEEK_UI_TEST_RESET_SETTINGS"] == "1" {
            AppSettings.resetForUITesting()
        }

        if let snapshotPath = ProcessInfo.processInfo.environment["LINGOPEEK_RENDER_SETTINGS_SNAPSHOT"] {
            renderSettingsSnapshotAndTerminate(snapshotPath)
            return
        }

        let environment = ProcessInfo.processInfo.environment
        let openSettingsOnLaunch = environment["LINGOPEEK_OPEN_SETTINGS"] == "1"
        let openHubOnLaunch = environment["LINGOPEEK_OPEN_HUB"] == "1"
        let hubLaunchSection = LingobarHubSection(rawValue: environment["LINGOPEEK_OPEN_HUB_SECTION"] ?? "")
        let uiTestMode = ProcessInfo.processInfo.environment["LINGOPEEK_UI_TEST_MODE"] == "1"
        let launchHubSection = openSettingsOnLaunch
            ? LingobarHubSection.settings
            : (openHubOnLaunch ? (hubLaunchSection ?? .collection) : nil)
        NSApp.setActivationPolicy(openSettingsOnLaunch || openHubOnLaunch || uiTestMode ? .regular : .accessory)
        let appUpdater = AppUpdater()
        self.appUpdater = appUpdater
        controller = LingobarController(appUpdater: appUpdater)
        controller?.start(openSettingsOnLaunch: openSettingsOnLaunch, openHubOnLaunch: launchHubSection)
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
