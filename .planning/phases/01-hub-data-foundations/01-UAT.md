---
status: testing
phase: 01-hub-data-foundations
source: [01-VERIFICATION.md]
started: 2026-06-27T16:07:14Z
updated: 2026-06-27T16:07:14Z
---

# Phase 1 UAT - Hub Data Foundations

## Current Test

number: 1
name: Successful AI completion writes history
expected: |
  Configure AI, trigger a successful translate/grammar/rewrite/examples/pronounce action,
  and inspect Application Support/LingoPeek/history.json.

  Expected result: one compact newest-first record is appended for the completed action
  after the result appears. The record contains only user-visible fields such as id,
  action, itemType, visibleText, copyText, note, sourceText, sourceAppName, and createdAt.
  It must not contain token, provider, model, base URL, raw prompt, raw provider JSON,
  Authorization header, request body, or error body data.
awaiting: user response

## Tests

### 1. Successful AI completion writes history

expected: |
  A successful Lingobar language action appends one compact history record to
  Application Support/LingoPeek/history.json.
result: pending

### 2. Non-success paths do not write history

expected: |
  Setup gate, grammar fixture, copy/collect, stale completions, decode errors, and
  provider/network errors leave history unchanged.
result: pending

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps

None recorded yet.
