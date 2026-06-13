# LingoPeek Context

## Product

LingoPeek is a native macOS prototype for a selection-first language and AI bar. The product direction currently uses Lingobar as the in-app product name.

Working positioning:

> 选中即解析，输入即生成。

## Core Concepts

- **Lingobar**: The floating language tool layer that appears after text selection or direct input.
- **Selection-first interaction**: The primary workflow starts from selected text in any macOS app.
- **Language action**: A user action such as translation, breakdown, collection, examples, or pronunciation.
- **Result panel**: The expanded output area below the bar.
- **Phrase store**: Local saved expressions for later review and reuse.

## Product Boundaries

LingoPeek is focused on reading, writing, and remembering English. It is not intended to become a general productivity launcher, file automation tool, or full agent workspace.

## Technical Shape

- Swift package.
- Native macOS app using SwiftUI and AppKit.
- Core language logic lives under `Sources/LingobarCore/`.
- The app shell and UI live under `Sources/LingoPeekApp/`.
- Zero-dependency verification lives in `Sources/LingoPeekCoreChecks/`.

## Documentation

- Product brief: `docs/product-brief.md`
- Architecture decisions: `docs/adr/`
