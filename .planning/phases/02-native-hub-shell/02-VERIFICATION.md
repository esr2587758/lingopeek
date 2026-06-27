# Phase 2 Verification - Native Hub Shell

**Status:** Passed
**Verified:** 2026-06-28

## Automated Checks

- `swift build --product LingoPeek` passed.
- `swift run LingoPeekCoreChecks` passed.

## Source Gates Added

`LingoPeekCoreChecks` now asserts:

- `LingobarHubWindowController` exists.
- The Hub frame is locked to `NSSize(width: 920, height: 624)`.
- The sidebar width constant is `188`.
- The detail width constant is `320`.
- The native navigation model includes collection, history, and settings.
- Display labels include `收藏`, `历史`, and `设置`.
- Collection/history use `PhraseStore.defaultStore()`, `LingobarHistoryStore.defaultStore()`, and `LingobarHubLibrary` adapters.
- Normal settings entry points route to Hub settings.
- `LINGOPEEK_OPEN_HUB` and `LINGOPEEK_OPEN_HUB_SECTION` exist for deterministic UI launch.

## Native UI Evidence

- Built a temporary `/tmp/LingoPeekHubUITest.app` wrapper around `.build/debug/LingoPeek`.
- Launched it with `LINGOPEEK_OPEN_HUB=1` and `LINGOPEEK_OPEN_HUB_SECTION=collection`.
- Quartz/WindowServer reported an onscreen `Lingobar Hub` window. The app source enforces a 920x624 AppKit content size on every show; WindowServer capture bounds for the transparent borderless window can reflect visible/shadow trimming rather than the content frame.
- A first screenshot confirmed the dark glass Hub rendered with sidebar navigation, collection list, and detail pane.
- After screenshot review, fixed a sidebar brand wrapping issue and replaced an unavailable SF Symbol in the primary detail action.

## Tool Limitation

The Computer Use plugin was attempted as requested, but `get_app_state` returned `cgWindowNotFound` for this borderless AppKit window even while Quartz reported the onscreen `Lingobar Hub` window. Verification therefore used WindowServer enumeration, build checks, source gates, and local screenshot capture as the reliable evidence path.
