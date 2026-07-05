import Foundation

public struct LingobarCollectionFragment: Equatable, Sendable {
    public var title: String
    public var note: String
    public var type: String
    public var rows: [LingobarRow]

    public init(
        title: String,
        note: String,
        type: String,
        rows: [LingobarRow] = []
    ) {
        self.title = title
        self.note = note
        self.type = type
        self.rows = rows
    }

    public func resultSnapshot(
        action: LanguageAction,
        shortcut: String
    ) -> LingobarResult {
        let summary = note.isEmpty ? title : note
        let snapshotRows = rows.isEmpty ? [LingobarRow(type, title)] : rows
        return LingobarResult(
            title: action.title,
            shortcut: shortcut,
            summary: summary,
            rows: snapshotRows,
            sideTitle: "后续动作",
            chips: [],
            moreActionTitle: action.moreActionTitle,
            defaultCollectionItem: DefaultCollectionItem(
                title: title,
                note: note,
                type: type
            )
        )
    }
}

public enum LingobarRelaunchPlan: Equatable, Sendable {
    case openSnapshot(LingobarStoredResultSnapshot)
    case requestLLM(LanguageAction)
}

public enum LingobarRelaunchPlanner {
    public static func plan(
        snapshot: LingobarResult?,
        sourceAction: LanguageAction?,
        requestedAction: LanguageAction?
    ) -> LingobarRelaunchPlan {
        plan(
            storedSnapshot: snapshot.map { LingobarStoredResultSnapshot(result: $0) },
            sourceAction: sourceAction,
            requestedAction: requestedAction
        )
    }

    public static func plan(
        snapshots: [String: LingobarStoredResultSnapshot],
        sourceAction: LanguageAction?,
        requestedAction: LanguageAction?
    ) -> LingobarRelaunchPlan {
        let fallbackAction = requestedAction ?? sourceAction ?? .translate
        guard let requestedAction else {
            return plan(
                storedSnapshot: preferredSnapshot(in: snapshots, sourceAction: sourceAction),
                sourceAction: sourceAction,
                requestedAction: nil
            )
        }
        if let snapshot = snapshots[requestedAction.rawValue] {
            return .openSnapshot(snapshot)
        }
        guard let sourceAction,
              requestedAction != sourceAction else {
            return plan(
                storedSnapshot: preferredSnapshot(in: snapshots, sourceAction: sourceAction),
                sourceAction: sourceAction,
                requestedAction: requestedAction
            )
        }
        return .requestLLM(fallbackAction)
    }

    public static func plan(
        storedSnapshot: LingobarStoredResultSnapshot?,
        sourceAction: LanguageAction?,
        requestedAction: LanguageAction?
    ) -> LingobarRelaunchPlan {
        let fallbackAction = requestedAction ?? sourceAction ?? .translate
        guard let storedSnapshot else {
            return .requestLLM(fallbackAction)
        }
        guard let requestedAction,
              let sourceAction,
              requestedAction != sourceAction else {
            return .openSnapshot(storedSnapshot)
        }
        return .requestLLM(requestedAction)
    }

    private static func preferredSnapshot(
        in snapshots: [String: LingobarStoredResultSnapshot],
        sourceAction: LanguageAction?
    ) -> LingobarStoredResultSnapshot? {
        if let sourceAction,
           let snapshot = snapshots[sourceAction.rawValue] {
            return snapshot
        }
        for action in LanguageAction.selectionActions where action != .collect {
            if let snapshot = snapshots[action.rawValue] {
                return snapshot
            }
        }
        return snapshots.values.first
    }
}
