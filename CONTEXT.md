# LingoPeek Context

## Product

LingoPeek is a native macOS prototype for a selection-first language bar. The product direction currently uses Lingobar as the in-app product name.

Working positioning:

> 选中即理解，输入即改写。

## Core Concepts

- **Lingobar**: The floating language tool layer that appears after text selection or direct input.
- **Selection-first interaction**: The primary workflow starts from selected text in any macOS app.
- **Language action**: A user action such as translation, grammar, rewrite, collection, examples, or pronunciation.
- **Understand**: The product-level promise for selected text. Understanding includes the default translation result plus optional deeper actions such as grammar, examples, collection, and rewrite; avoid using `解析` as the umbrella term.
- **Translate**: The user-facing language action labeled `翻译`. It helps the user understand current text, usually by producing a Chinese explanation or translation while preserving the source meaning.
- **Grammar view**: The user-facing language action labeled `语法`. It opens grammar breakdown content such as sentence structure, clauses, modifiers, and logic relationships; avoid labeling this action `拆解` in user-facing toolbar copy.
- **Grammar availability**: Grammar view is for English content. When the selected or typed content is Chinese or mixed-language, the MVP should keep `语法` in its toolbar position but disable it rather than hiding it; this preserves action order while avoiding Chinese grammar analysis.
- **Rewrite**: The user-facing language action labeled `改写`. It helps the user express themselves in natural English by turning selected text, typed Chinese, typed English, mixed-language notes, or rough ideas into better English; avoid `扩写`, `扩展`, or generic `生成` for this primary expression action.
- **Input mode**: The no-selection workflow. In the MVP, input mode serves rewrite and natural English expression only; avoid positioning it as open-ended `Ask AI` or general question answering.
- **Examples**: The user-facing language action labeled `例句`. It helps users imitate and transfer the current expression into new English sentences; for the MVP, prefer collocation examples for words/phrases, same-structure examples for sentences, and same-tone or same-scenario examples for practical expressions.
- **Pronunciation**: The user-facing language action labeled `发音`. It is a lightweight playback and pronunciation reference for selected text, with optional phonetics, stress, or slower playback; avoid expanding it into a full shadowing, recording, or scoring practice module in the MVP.
- **Default selection action**: Selected English opens with translation by default, while selected Chinese or mixed-language text opens with rewrite by default. Rewrite remains a first-level action near the front of the toolbar. Preferred primary order is `翻译 / 语法 / 改写 / 例句 / 收藏 / 发音`, with copy treated as a compact system utility.
- **Action order stability**: Language detection should not reorder the toolbar. Keep the same action order across English, Chinese, and mixed-language content; only the default action and availability state may change.
- **Language detection visibility**: Lingobar should not explicitly show language-detection labels in the MVP. The chosen default action and result title should communicate intent, and users can switch actions if the default is wrong.
- **Action priority**: The user-configurable ordering and prominence of language actions in Lingobar. Default priority should support the first-run reading workflow, but users can later prioritize actions such as rewrite or grammar for their own habits.
- **Write-back**: Returning generated text to the source app. The MVP should not make `插入当前 App` a primary action; use copy as the write-back path first, with direct replacement or insertion left for later versions.
- **Contextual more action**: The third bottom action in the result panel. Avoid the generic label `继续展开`; use context-specific labels such as `解释更多` for translation, `继续拆解` for grammar, `更多版本` for rewrite, `更多例句` for examples, or `慢速播放` for pronunciation.
- **Result panel**: The expanded output area below the bar.
- **Collection**: The local place for everything the user has collected. User-facing copy should call this area `收藏`; avoid abstract names such as `表达库`.
- **Collect**: The user action of adding a word, phrase, sentence, or generated result to the collection. User-facing copy should use `收藏`; avoid `保存` or `收录` for this language-learning action.
- **Collected item type**: The source-based type label for a collected item, such as `文本` for directly collected selected text, `英文` for a rewrite result, `例句` for an example, `句型` for a grammar pattern, or `短语` for a phrase or collocation.
- **Default collect target**: The item Lingobar collects when the user presses `收藏`. Collection follows the current content panel rather than always collecting the original selection: translation collects a key English expression or source text, rewrite collects the primary rewritten sentence, examples collect the highlighted or first example, and grammar view collects the reusable sentence pattern. Directly collecting the original selection should be a separate lightweight affordance such as `收藏原文`.
- **Result shape**: The expected output shape for each language action. Rewrite should show one primary result plus optional style variants, examples should show multiple reusable sentences, and grammar view should show multiple structure blocks plus one reusable sentence pattern.

## Product Boundaries

LingoPeek is focused on reading, writing, and remembering English. It is not intended to become a general productivity launcher, file automation tool, or full agent workspace.

The MVP should explicitly serve English reading and English expression rather than positioning itself as a multilingual AI toolbar. Additional target languages can remain a future possibility, but they should not shape the first version's terminology or interaction model.

## Technical Shape

- Swift package.
- Native macOS app using SwiftUI and AppKit.
- Core language logic lives under `Sources/LingobarCore/`.
- The app shell and UI live under `Sources/LingoPeekApp/`.
- Zero-dependency verification lives in `Sources/LingoPeekCoreChecks/`.

## Documentation

- Product brief: `docs/product-brief.md`
- Architecture decisions: `docs/adr/`
