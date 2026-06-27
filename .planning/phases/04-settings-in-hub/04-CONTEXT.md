# Phase 4: Settings In Hub - Context

**Gathered:** 2026-06-28
**Status:** Complete
**Mode:** Autonomous vertical slice

## Phase Boundary

Move settings behavior into the native Hub while preserving existing persistence and notifications:

- All existing settings sections visible in Hub.
- Native controls for general, AI, permissions, trigger, actions, collection, and about sections.
- Writes go through existing `AppSettings.save...` APIs.
- Existing environment/local token precedence remains intact.

## Existing Contracts

- `LingobarSettingsSectionDescriptor.all` provides the canonical settings sections.
- `LingobarSettingsSnapshot` mirrors persisted settings and setup gate state.
- `AppSettings` owns persistence keys, save methods, setup gate status, hotkey reset, and notifications.
- `LingobarController` listens for `settingsDidChangeNotification` to update floating Lingobar behavior.

## Decisions

- Do not embed the old `SettingsView`; rebuild a Hub-native settings surface with the same data contract.
- Keep token entry local and explicit: save and clear buttons write through `LocalTokenStore` via `AppSettings`.
- Keep settings controls compact and operational, consistent with the Hub design.

