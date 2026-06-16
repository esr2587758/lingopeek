import Foundation

enum LocalTokenStore {
    private static let tokenKey = "aiAPIToken"

    static func readToken() -> String {
        UserDefaults.standard.string(forKey: tokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static func saveToken(_ token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            deleteToken()
            return
        }
        UserDefaults.standard.set(trimmed, forKey: tokenKey)
    }

    static func deleteToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
