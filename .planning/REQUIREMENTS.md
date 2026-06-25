# Requirements: LingoPeek Native Lingobar Hub

**Defined:** 2026-06-26
**Core Value:** Users can manage saved language material, revisit previous language actions, and change Lingobar settings in one native window without breaking the selection-first Lingobar workflow.

## v1 Requirements

### Hub Shell

- [ ] **HUB-01**: User can open a native Lingobar Hub window sized and structured like the reference design, with a dark glass 920x624 shell and 188pt left sidebar.
- [ ] **HUB-02**: User can switch between `收藏`, `历史`, and `设置` from the sidebar without opening separate windows.
- [ ] **HUB-03**: User can see setup readiness in the sidebar footer as `已就绪` or `需完成必填项` based on AI access and Accessibility permission.
- [ ] **HUB-04**: User can close the Hub with Escape or Command-W, and can drag the borderless Hub from its header/sidebar drag regions.
- [ ] **HUB-05**: Existing settings entry points open the Hub to the settings section instead of the old standalone settings window.

### Collection

- [ ] **COLL-01**: User can view locally saved phrases from `PhraseStore` in the Hub collection list.
- [ ] **COLL-02**: User can search collection items by visible text or notes.
- [ ] **COLL-03**: User can filter collection items by item type using chip controls.
- [ ] **COLL-04**: User can select a collection item and view its details in the right detail pane.
- [ ] **COLL-05**: User can copy a collection item from either the card or detail pane.
- [ ] **COLL-06**: User can delete a collection item and see the list/detail state update immediately.
- [ ] **COLL-07**: User can relaunch a collection item into the Lingobar language workflow when supported.

### History

- [ ] **HIST-01**: Lingobar records completed language actions into a local bounded history store.
- [ ] **HIST-02**: User can view recent history records in the Hub history list with action badges, item type, source, and relative time.
- [ ] **HIST-03**: User can search history records by visible text or notes.
- [ ] **HIST-04**: User can filter history by action (`翻译`, `语法`, `改写`, `例句`, `发音`) using chip controls.
- [ ] **HIST-05**: User can select a history item and view its details in the right detail pane.
- [ ] **HIST-06**: User can copy, delete, and clear history records.
- [ ] **HIST-07**: User can save a history item into collection without creating an obvious duplicate in the current Hub session.
- [ ] **HIST-08**: User can relaunch a history item into the Lingobar language workflow when supported.

### Settings

- [ ] **SET-01**: User can access settings subsections inside the Hub: `通用`, `AI 服务`, `权限`, `划词与唤起`, `语言动作`, `收藏`, and `关于`.
- [ ] **SET-02**: User can change launch and menu bar preferences from the Hub, with changes persisted through existing `AppSettings` behavior.
- [ ] **SET-03**: User can change appearance scheme from the Hub using cards styled like the reference design.
- [ ] **SET-04**: User can configure AI provider, model, base URL, API key, and connection test behavior from the Hub without changing existing token precedence rules.
- [ ] **SET-05**: User can open Accessibility settings from the Hub permissions section when permission is missing.
- [ ] **SET-06**: User can configure trigger behavior, selection float button, hotkey, action ordering, default actions, collection behavior, and clipboard behavior from the Hub.
- [ ] **SET-07**: Settings changes made in the Hub update the floating Lingobar behavior through existing notifications.

### Fidelity and Verification

- [ ] **FID-01**: Hub visual tokens match the reference design's major dimensions, colors, rounded corners, hairlines, chip styling, card styling, detail pane, and toast treatment.
- [ ] **FID-02**: Hub implementation uses native SwiftUI/AppKit controls and avoids `WKWebView` or web runtime embedding.
- [ ] **FID-03**: Automated checks cover the new history store and any collection/settings transformation logic.
- [ ] **FID-04**: A deterministic render or screenshot workflow exists for comparing the native Hub against the local reference screenshot.
- [ ] **FID-05**: `swift build --product LingoPeek` and `swift run LingoPeekCoreChecks` pass after implementation.

## v2 Requirements

### Sync

- **SYNC-01**: User can sync collection and history across devices.
- **SYNC-02**: User can export collection/history to a study tool or document format.

### Advanced History

- **AHIST-01**: User can group history by source app or document.
- **AHIST-02**: User can configure history retention and privacy rules.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cloud account and sync | Local-first Hub is the current milestone; accounts would broaden security and product scope. |
| WebView-based implementation | User requested native SwiftUI fidelity and native behavior. |
| Voice input enablement | Existing product boundary keeps microphone permission out of MVP. |
| Direct insertion into source apps | Copy/relaunch is sufficient and safer for the first Hub milestone. |
| Rebuilding the floating Lingobar result panel | The Hub integrates with the existing workflow rather than redesigning it. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HIST-01 | Phase 1 | Pending |
| COLL-01 | Phase 1 | Pending |
| COLL-05 | Phase 1 | Pending |
| HIST-02 | Phase 1 | Pending |
| HIST-06 | Phase 1 | Pending |
| HUB-01 | Phase 2 | Pending |
| HUB-02 | Phase 2 | Pending |
| HUB-03 | Phase 2 | Pending |
| HUB-04 | Phase 2 | Pending |
| FID-01 | Phase 2 | Pending |
| FID-02 | Phase 2 | Pending |
| COLL-02 | Phase 3 | Pending |
| COLL-03 | Phase 3 | Pending |
| COLL-04 | Phase 3 | Pending |
| COLL-06 | Phase 3 | Pending |
| COLL-07 | Phase 3 | Pending |
| HIST-03 | Phase 3 | Pending |
| HIST-04 | Phase 3 | Pending |
| HIST-05 | Phase 3 | Pending |
| HIST-07 | Phase 3 | Pending |
| HIST-08 | Phase 3 | Pending |
| SET-01 | Phase 4 | Pending |
| SET-02 | Phase 4 | Pending |
| SET-03 | Phase 4 | Pending |
| SET-04 | Phase 4 | Pending |
| SET-05 | Phase 4 | Pending |
| SET-06 | Phase 4 | Pending |
| SET-07 | Phase 4 | Pending |
| HUB-05 | Phase 5 | Pending |
| FID-03 | Phase 5 | Pending |
| FID-04 | Phase 5 | Pending |
| FID-05 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 32 total
- Mapped to phases: 32
- Unmapped: 0

## Definition of Done

- The Hub replaces settings entry points and opens to the correct section.
- Collection and history both use real local data stores.
- Settings in the Hub persist and notify the existing app.
- Native Hub rendering is visually close to the local reference and has a repeatable verification path.
- `swift build --product LingoPeek` and `swift run LingoPeekCoreChecks` pass.

---
*Requirements defined: 2026-06-26*
*Last updated: 2026-06-26 after initial definition*
