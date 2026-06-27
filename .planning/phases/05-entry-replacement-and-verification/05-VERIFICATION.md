# Phase 5 Verification - Entry Replacement And Verification

**Status:** Passed
**Verified:** 2026-06-28

## Automated Evidence

- `swift build --product LingoPeek` passed.
- `swift run LingoPeekCoreChecks` passed.

## Native UI Evidence

- Temporary `/tmp/LingoPeekHubUITest.app` launched with `LINGOPEEK_OPEN_HUB=1`.
- WindowServer reported an onscreen `Lingobar Hub` window. Source gates enforce the 920x624 AppKit content size, while WindowServer capture bounds can reflect transparent borderless-window trimming.
- Screenshot review confirmed the Hub shell, sidebar navigation, collection list, detail pane, and dark glass visual direction.
- UI follow-up fixed the observed brand wrapping and unavailable SF Symbol.

## Known Verification Gap

Computer Use could not attach to the borderless AppKit Hub window and returned `cgWindowNotFound`. This prevented click-by-click plugin UAT in this run. WindowServer evidence and local screenshot review were used instead.
