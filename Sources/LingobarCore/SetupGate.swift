public struct SetupGateStatus: Equatable, Sendable {
    public var aiAccessConfigured: Bool
    public var accessibilityPermissionGranted: Bool

    public init(aiAccessConfigured: Bool, accessibilityPermissionGranted: Bool) {
        self.aiAccessConfigured = aiAccessConfigured
        self.accessibilityPermissionGranted = accessibilityPermissionGranted
    }

    public var requiredAction: SetupGateAction {
        aiAccessConfigured && accessibilityPermissionGranted ? .useLingobar : .completeSetup
    }
}

public enum SetupGateAction: Equatable, Sendable {
    case completeSetup
    case useLingobar
}
