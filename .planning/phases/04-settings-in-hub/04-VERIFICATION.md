# Phase 4 Verification - Settings In Hub

**Status:** Passed
**Verified:** 2026-06-28

## Evidence

- `swift build --product LingoPeek` passed.
- `swift run LingoPeekCoreChecks` passed.
- Hub settings controls call existing `AppSettings.save...` APIs rather than introducing new persistence.
- `LingobarController` already observes settings notifications, so updates continue flowing to the floating Lingobar.

## Residual Risk

The old `SettingsView` and `SettingsWindowController` remain in source for now, but normal settings entry points no longer route to them. They can be deleted in a later cleanup once no tests or snapshot utilities depend on them.

