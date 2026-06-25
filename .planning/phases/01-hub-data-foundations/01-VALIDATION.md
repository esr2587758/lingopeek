---
phase: 1
slug: hub-data-foundations
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-26
---

# Phase 1 - Validation Strategy

Per-phase validation contract for Hub Data Foundations.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Custom Swift executable checks in `LingoPeekCoreChecks` |
| Config file | `Package.swift` declares the executable target |
| Quick run command | `swift run LingoPeekCoreChecks` |
| Full suite command | `swift build --product LingoPeek && swift run LingoPeekCoreChecks` |
| Estimated runtime | Under 60 seconds on a warm local build |

## Sampling Rate

- After every task commit: run `swift run LingoPeekCoreChecks`
- After every plan wave: run `swift build --product LingoPeek && swift run LingoPeekCoreChecks`
- Before `$gsd-verify-work`: full suite must be green
- Max feedback latency: one task

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | HIST-01, COLL-01, COLL-05, HIST-02, HIST-06 | T-1-01, T-1-02 | Red CoreChecks cover history persistence, privacy, adapters, and copy/delete/clear contracts | executable check | `swift run LingoPeekCoreChecks` | Missing | pending |
| 1-01-02 | 01 | 1 | HIST-01, COLL-01, COLL-05, HIST-02 | T-1-01 | Core records/adapters persist compact user-visible data only and keep collection metadata adapter-only | executable check + source gate | `swift run LingoPeekCoreChecks` | Missing | pending |
| 1-01-03 | 01 | 1 | HIST-01, HIST-06 | T-1-02 | Delete, clear, append, save, and cap mutate only local history data | executable check | `swift run LingoPeekCoreChecks` | Missing | pending |
| 1-02-01 | 02 | 2 | HIST-01 | T-1-03 | App integration records only non-stale successful AI completions and source-gates forbidden paths | executable check + source assertion | `swift build --product LingoPeek && swift run LingoPeekCoreChecks` | Missing | pending |
| 1-02-02 | 02 | 2 | HIST-01, COLL-01, COLL-05, HIST-02, HIST-06 | T-1-01, T-1-02, T-1-03 | Final build/check/scope gates prove Phase 1 remains data-only | executable check + source assertion | `swift build --product LingoPeek && swift run LingoPeekCoreChecks` | Missing | pending |

## Threat References

| Threat | Risk | Required Control |
|--------|------|------------------|
| T-1-01 | Secrets or raw provider payloads leak into `history.json` | History builder must not accept provider config, token, Authorization header, model, base URL, raw prompts, raw AI JSON, or error bodies |
| T-1-02 | History mutation damages collection storage | `LingobarHistoryStore` uses its own `history.json`; collection remains owned by `PhraseStore` |
| T-1-03 | Stale AI completion persists after fast action switching | Record only after the `activeAIRequestID` guard in `LingobarViewModel.runAIIfAvailable` |

## Plan Requirements

- [ ] `Sources/LingobarCore/LingobarHistoryStore.swift` or equivalent core file defines `LingobarHistoryRecord` and `LingobarHistoryStore`.
- [ ] `Sources/LingobarCore/LingobarHubData.swift` or equivalent core file defines collection/history adapter contracts.
- [ ] `Sources/LingoPeekCoreChecks/main.swift` includes checks for history append/load/cap, delete/clear, privacy, history record building, collection adapter copy text, and ViewModel history-recording source placement.
- [ ] `Sources/LingoPeekApp/LingobarViewModel.swift` records history only after successful decode and the current-request guard.

## Manual-Only Verifications

All Phase 1 behaviors have automated or source-assertion verification. Visual Hub verification starts in later UI phases.

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency under one task
- [x] `nyquist_compliant: true` set in frontmatter

Approval: pending
