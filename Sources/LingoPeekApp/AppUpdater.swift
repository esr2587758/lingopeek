import AppKit
import Sparkle

@MainActor
final class AppUpdater {
    private let updaterController: SPUStandardUpdaterController?

    init(bundle: Bundle = .main) {
        guard Self.hasSparkleConfiguration(in: bundle) else {
            updaterController = nil
            return
        }
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func makeCheckForUpdatesMenuItem() -> NSMenuItem? {
        guard let updaterController else {
            return nil
        }
        let item = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        item.target = updaterController
        return item
    }

    private static func hasSparkleConfiguration(in bundle: Bundle) -> Bool {
        let feedURL = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String
        let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        return !trimmed(feedURL).isEmpty && !trimmed(publicKey).isEmpty
    }

    private static func trimmed(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
