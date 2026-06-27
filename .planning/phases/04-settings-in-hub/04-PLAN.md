---
phase: 04-settings-in-hub
status: complete
created: 2026-06-28T00:00:00Z
completed: 2026-06-28T00:00:00Z
mode: mvp
---

# Phase 4 Plan - Settings In Hub

## Goal

Port real settings behavior into the Hub with native controls and existing `AppSettings` persistence.

## Tasks

### Task 1 - Settings subnav

- Reuse `LingobarSettingsSectionDescriptor.all`.
- Show setup attention dots for AI and permissions when setup gate is incomplete.

### Task 2 - Settings controls

- General: launch at login, menu bar icon, appearance.
- AI: provider, model, base URL, token save/clear/reveal.
- Permissions: accessibility status and system settings link.
- Trigger: selection trigger, floating button, hotkey reset.
- Actions: action ordering and default actions.
- Collection: collection target and clipboard fallback.
- About: product identity.

### Task 3 - Persistence

- Use existing `AppSettings.save...` methods for every setting.
- Refresh `LingobarSettingsSnapshot` after writes.
- Preserve existing notifications.

## Verification

- `swift build --product LingoPeek`
- `swift run LingoPeekCoreChecks`
- Source review of Hub settings bindings.

