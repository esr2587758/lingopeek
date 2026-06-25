# Project Research Summary

## Key Findings

**Stack:** Implement the Hub natively with SwiftUI in the app target plus an AppKit borderless window controller. Reuse `AppSettings`, `LingobarSettingsSnapshot`, `PhraseStore`, and existing SwiftPM checks. Add a small Foundation history store rather than a new dependency.

**Table Stakes:** The Hub needs the reference sidebar, collection list/detail, history list/detail, settings subnav, setup-gate footer, search/filter controls, cards, action buttons, and toast feedback. The settings section must preserve real current settings behavior.

**Watch Out For:** The two riskiest areas are replacing settings entry points without breaking setup flow, and adding real history persistence without storing sensitive AI/provider details. Visual drift should be checked through a deterministic snapshot path.

## Implications for Roadmap

1. Start with persistence contracts because Data 3 requires real history and collection behavior.
2. Build the native shell before deep settings wiring so visual dimensions and routing are stable.
3. Wire settings through existing persistence rather than migrating settings keys.
4. Finish with snapshot/render verification and reference-fidelity polish.

## Sources

- `.planning/codebase/ARCHITECTURE.md`
- `.planning/codebase/STACK.md`
- `CONTEXT.md`
- `docs/adr/0001-ai-required-language-results.md`
- `docs/adr/0002-openai-compatible-ai-settings.md`
- `docs/adr/0003-structured-ai-results.md`
- `docs/adr/0004-grammar-specific-structured-results.md`
- `docs/adr/0005-native-grammar-visualization.md`
- `designs/lingobar-hub/Lingobar Hub.html`
- `designs/lingobar-hub/app.jsx`
- `designs/lingobar-hub/cards.jsx`
- `designs/lingobar-hub/data.jsx`
- `.omx/state/lingobar-hub/reference-full.png`
