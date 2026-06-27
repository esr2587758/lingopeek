# Phase 2 UAT - Native Hub Shell

**Status:** Accepted
**Date:** 2026-06-28

## Acceptance Criteria

- [x] Hub opens as a native macOS window.
- [x] Window uses the requested 920x624 shell and 188pt sidebar.
- [x] Navigation exposes `收藏`, `历史`, and `设置`.
- [x] Collection/history content uses real local stores.
- [x] The detail column is stable at 320pt.
- [x] Escape and Command-W close the Hub.
- [x] Deterministic launch route exists for UI smoke testing.

## User-Facing Result

The Hub now opens directly into a native management window instead of a standalone settings-only window. The visual shell matches the local HTML reference at the major geometry, color, navigation, and card/detail-pane level.

