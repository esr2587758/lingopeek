# Project Research: Architecture

## Recommended Component Boundaries

### `LingobarHubWindowController`

Owns the main Hub window:

- Creates a 920x624 borderless `NSWindow`.
- Hosts `LingobarHubView`.
- Implements Escape / Command-W close behavior.
- Provides drag regions matching the reference sidebar/header surfaces.
- Exposes `show(section:)` so settings entry points can open the Hub directly to settings.

### `LingobarHubView`

Owns the SwiftUI visual shell:

- Sidebar navigation and setup-gate footer.
- Collection/history/settings content switching.
- Toast presentation.
- Local state for selected section, selected item, search query, filter, and active settings subsection.

### Hub Library Models

Foundation/Core-friendly records:

- `HubLibraryItem` view model that can represent collection phrases and history records.
- `LingobarHistoryRecord` for persisted history.
- `LingobarHistoryStore` for JSON load/save, capped retention, delete, clear, and append.

### Existing Settings Boundary

Reuse:

- `AppSettings.makeSettingsSnapshot()`
- `AppSettings.save...` methods
- `LingobarSettingsSnapshot`
- `LingobarSettingsSectionDescriptor`
- `LanguageAction`

Avoid duplicating settings keys or adding parallel state.

## Data Flow

1. User chooses Settings from the menu bar, clicks a floating Lingobar gear, or uses the setup-gate AI settings action.
2. `LingobarController` asks the Hub controller to show the `settings` section.
3. `LingobarHubView` loads current saved phrases through `PhraseStore.defaultStore()` and history records through the new history store.
4. Collection actions mutate `PhraseStore` and refresh the list.
5. History actions mutate `LingobarHistoryStore`, optionally save a history item into `PhraseStore`, or relaunch an item into Lingobar.
6. Settings controls write through existing `AppSettings`, which posts `settingsDidChangeNotification`.
7. `LingobarController` continues observing settings changes and updates floating-panel behavior as it does today.

## Build Order Implications

1. Build history models/store first so real history has a stable contract.
2. Build the Hub shell and static visual hierarchy next, using prototype data adapters where needed.
3. Wire collection and history to stores.
4. Port settings controls into the Hub and replace entry points.
5. Add rendering/verification paths and polish fidelity.

## Confidence

High. The pattern matches existing AppKit controller plus SwiftUI view boundaries already used by `SettingsWindowController` and `LingobarController`.
