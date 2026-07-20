# LingoPeek Agent Guide

This repository is a native macOS Swift package for LingoPeek/Lingobar, a selection-first language and AI bar.

## Working agreements

- Keep changes small, reviewable, and reversible.
- Prefer existing Swift, SwiftUI, and AppKit patterns in `Sources/` before introducing new abstractions.
- Do not commit local runtime state, build artifacts, API keys, or machine-specific settings.
- Do not use OMX runtime workflows in this repository unless the user explicitly asks to re-enable them.

## Verification

- Every code change must be verified before completion. For app-facing code changes, use `$verify-app-change` (`/Users/lancer/.codex/skills/verify-app-change/SKILL.md`) and follow its launch, interaction, screenshot/visual check, log review, and automated-check loop before the final response.
- Build the app with `swift build --product LingoPeek`.
- Run the zero-dependency check suite with `swift run LingoPeekCoreChecks`.
- DeepSeek connectivity checks require secrets and should be run only with user-provided environment variables.

## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues for `esr2587758/lingopeek`. See `docs/agents/issue-tracker.md`.

### Triage labels

Triage uses the default five-label vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repo with root `CONTEXT.md` and ADRs under `docs/adr/`. See `docs/agents/domain.md`.
