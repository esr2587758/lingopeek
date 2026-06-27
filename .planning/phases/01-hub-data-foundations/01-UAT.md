---
status: complete
phase: 01-hub-data-foundations
source: [01-VERIFICATION.md]
started: 2026-06-27T16:07:14Z
updated: 2026-06-27T16:26:25Z
---

# Phase 1 UAT - Hub Data Foundations

## Current Test

[testing complete]

## Tests

### 1. Successful AI completion writes history

expected: |
  A successful Lingobar language action appends one compact history record to
  Application Support/LingoPeek/history.json.
result: pass
source: automated-ui
evidence: |
  Launched the current SwiftPM build through a temporary /tmp/LingoPeekUITest.app
  wrapper and drove the native Lingobar input UI. A local OpenAI-compatible mock
  first returned a successful rewrite response and appended a newest-first record.
  Then the same native UI was run with the user-provided DeepSeek endpoint/model,
  producing a visible rewrite result and a second newest-first history record at
  ~/Library/Application Support/LingoPeek/history.json.

  Latest real-provider record fields observed: id, action, itemType, visibleText,
  copyText, note, sourceText, sourceAppName, createdAt. No token, provider, model,
  base URL, raw prompt, raw provider JSON, Authorization header, request body, or
  error body fields were present.

### 2. Non-success paths do not write history

expected: |
  Setup gate, grammar fixture, copy/collect, stale completions, decode errors, and
  provider/network errors leave history unchanged.
result: pass
source: automated-ui
evidence: |
  With history count at 1 after the mock success path, clicked native copy and
  collect controls; history count stayed 1 and the phrases store was restored from
  backup after the collection side effect. Replaced the mock provider with a
  malformed JSON response and triggered rewrite from the native UI; Lingobar showed
  the expected format-error UI and history count stayed 1. Stopped the mock provider
  and triggered rewrite again; Lingobar showed the provider/network error UI and
  history count stayed 1. Restarted with invalid AI configuration; the settings/setup
  gate opened and history count stayed 1.

  The stale-completion guard remains covered by the committed CoreChecks source gate:
  recording occurs only after the activeAIRequestID success guard, and forbidden
  setup/fixture/copy/collect/error regions contain no history append call.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None recorded yet.
