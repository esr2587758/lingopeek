import Foundation

enum AppVersion {
    static var displayString: String {
        let version = bundleValue(for: "CFBundleShortVersionString")
        let build = bundleValue(for: "CFBundleVersion")

        switch (version.isEmpty, build.isEmpty) {
        case (false, false):
            if version == build {
                return version
            }
            return "\(version) (build \(build))"
        case (false, true):
            return version
        case (true, false):
            return "build \(build)"
        case (true, true):
            return "开发版"
        }
    }

    private static func bundleValue(for key: String) -> String {
        let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
