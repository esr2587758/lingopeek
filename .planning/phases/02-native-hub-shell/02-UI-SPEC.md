---
phase: 02-native-hub-shell
status: ready
source: designs/lingobar-hub/Lingobar Hub.html
reference: .omx/state/lingobar-hub/reference-full.png
---

# Phase 2 UI Spec - Native Hub Shell

## Target Surface

The shipped surface is a native macOS SwiftUI/AppKit Hub window, not the prototype stage, menubar, or wallpaper. The window itself should visually match the reference Hub shell:

- Size: 920pt wide x 624pt tall.
- Window: borderless, transparent backing, rounded 16pt clipped surface, shadow, dark glass background.
- Sidebar: 188pt fixed width, right hairline divider, grouped navigation.
- Main: flexible content region with header/tooling and a two-column library layout (`1fr + 320pt`) for collection/history shell views.

## Visual Tokens

| Token | Value |
| --- | --- |
| Accent | `#6E8BFF` |
| Accent text | `#AAB6FF` |
| Accent weak | `rgba(110,139,255,0.16)` |
| Window glass | `rgba(28,30,40,0.82)` |
| Secondary glass | `rgba(40,43,56,0.60)` |
| Hairline | `rgba(255,255,255,0.09)` |
| Strong hairline | `rgba(255,255,255,0.15)` |
| Text primary | `rgba(255,255,255,0.95)` |
| Text secondary | `rgba(255,255,255,0.60)` |
| Text tertiary | `rgba(255,255,255,0.38)` |
| Chip | `rgba(255,255,255,0.06)` |
| Chip hover | `rgba(255,255,255,0.11)` |
| Black field | `rgba(0,0,0,0.22)` |
| OK | `#4FD0A0` |
| Warning | `#E0915C` |

## Layout Requirements

1. Sidebar brand row:
   - Spark/snowflake-like SF Symbol mark in an accent-weak 28x28 rounded square.
   - `Lingobar` label at 15pt semibold.
2. Sidebar navigation:
   - Group title `我的内容`, then `收藏` and `历史`.
   - Group title `应用`, then `设置`.
   - Each nav row has 26x26 icon well, primary label, secondary description, and optional count.
   - Active row uses accent-weak background and accent text.
3. Sidebar footer:
   - Shows `已就绪` in green when setup gate is ready.
   - Shows `需完成必填项` in warning color when setup is incomplete.
4. Collection/history shell:
   - Header with title and count.
   - Search field visually present at 220pt width.
   - Filter chip toolbar.
   - List column with cards and hairline divider.
   - Detail column width 320pt with stable empty state.
5. Settings shell:
   - Header `设置`.
   - Horizontal subnav with `通用`, `AI 服务`, `权限`, `划词与唤起`, `语言动作`, `收藏`, `关于`.
   - Phase 2 may show shell cards/placeholders for section bodies; Phase 4 ports full behavior.

## Interaction Requirements

1. The Hub can switch top-level sections without opening another window.
2. Escape closes the Hub.
3. Command-W closes the Hub.
4. Window drag works from the brand/header drag regions while preserving controls such as search and buttons.
5. A deterministic environment launch path opens the Hub for visual verification.

## Accessibility And Stability

- Use native Buttons/TextFields where controls are interactive.
- Keep icon buttons at stable square sizes.
- Text must not overlap in the 920x624 desktop window.
- Long content in cards/detail should wrap or truncate predictably.

## Out Of Scope For This Phase

- Complete search/filter behavior.
- Delete/clear/save-to-collection/relaunch workflows.
- Full settings persistence controls.
- Final screenshot comparison automation.

## Verification Gates

- `swift build --product LingoPeek`
- `swift run LingoPeekCoreChecks`
- Source assertions:
  - `LingobarHubWindowController` exists.
  - `LingobarHubView` exists.
  - Hub size constants include 920x624.
  - Sidebar width constant is 188.
  - Detail width constant is 320.
  - Navigation labels include `收藏`, `历史`, and `设置`.
  - A deterministic launch route such as `LINGOPEEK_OPEN_HUB` exists.

