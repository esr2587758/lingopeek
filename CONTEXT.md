# LingoPeek Context

## Product

LingoPeek is a native macOS prototype for a selection-first language bar. The product direction currently uses Lingobar as the in-app product name.

Working positioning:

> 选中即理解，输入即改写。

## Core Concepts

- **Lingobar**: The floating language tool layer that appears after text selection or direct input.
- **Selection-first interaction**: The primary workflow starts from selected text in any macOS app.
- **Language action**: A user action such as translation, grammar, rewrite, collection, examples, or pronunciation.
- **Custom Prompt Action**: A user-defined language action that applies a saved prompt to selected or typed text and appears alongside built-in language actions in Lingobar. It requires current text context, must have a name that does not duplicate built-in or other custom action names, can be removed by the user, extends the action set without redefining built-in actions, and produces the same structured result shape as other Lingobar language actions; the user writes an instruction, not a JSON schema. Removing one affects future action surfaces and advances any default-action choice that pointed to it to the next ranked eligible action, but does not delete past History records. It is not a result-panel tab or a generic chat entry; avoid calling it `custom tab`, `tab content`, or `Ask AI`.
- **Prompt template**: The saved instruction text for a Custom Prompt Action. Lingobar automatically supplies the selected or typed text as context; `{text}` is an optional placeholder for users who want to control the exact insertion point. Avoid calling this `grammar` because `语法` already names the Grammar view.
- **Understand**: The product-level promise for selected text. Understanding includes the default translation result plus optional deeper actions such as grammar, examples, collection, and rewrite; avoid using `解析` as the umbrella term.
- **Translate**: The user-facing language action labeled `翻译`. It helps the user understand current text, usually by producing a Chinese explanation or translation while preserving the source meaning.
- **Grammar view**: The user-facing language action labeled `语法`. It opens grammar breakdown content such as sentence structure, clauses, modifiers, and logic relationships; the expanded result may use `语法解析` as a descriptive title, but the toolbar action stays `语法`. Avoid labeling this action `拆解` in user-facing toolbar copy.
- **Grammar availability**: Grammar view is for English content. When the selected or typed content is Chinese or mixed-language, the MVP should keep `语法` in its toolbar position but disable it rather than hiding it; this preserves action order while avoiding Chinese grammar analysis.
- **Rewrite**: The user-facing language action labeled `改写`. It helps the user express themselves in natural English by turning selected text, typed Chinese, typed English, mixed-language notes, or rough ideas into better English; avoid `扩写`, `扩展`, or generic `生成` for this primary expression action.
- **Input mode**: The no-selection workflow. In the MVP, input mode defaults to rewrite and natural English expression; a user may explicitly choose a Custom Prompt Action for typed text, but input mode should not be positioned as open-ended `Ask AI` or general question answering.
- **Setup gate**: The product state that blocks normal Lingobar use until required setup is complete. In the MVP, required setup means AI access is configured and Accessibility permission is granted; without both, Lingobar should guide the user through setup rather than showing normal language actions or placeholder results.
- **Examples**: The user-facing language action labeled `例句`. It helps users imitate and transfer the current expression into new English sentences; for the MVP, prefer collocation examples for words/phrases, same-structure examples for sentences, and same-tone or same-scenario examples for practical expressions.
- **Pronunciation**: The user-facing language action labeled `发音`. It is a lightweight playback and pronunciation reference for selected text, with optional phonetics, stress, or slower playback; avoid expanding it into a full shadowing, recording, or scoring practice module in the MVP.
- **Voice input**: Dictating text into input mode. Voice input is outside the MVP; a microphone affordance may remain as a disabled or "not yet enabled" placeholder, but the app should not request microphone or speech-recognition permissions in the MVP.
- **Default selection action**: The action Lingobar runs first when the selection workflow opens. Factory defaults are translation for selected English and rewrite for selected Chinese or mixed-language text, but settings should respect the user's chosen result-producing built-in action or Custom Prompt Action even when action-specific availability or errors must be handled at runtime; save and collection actions cannot be default selection actions. If the chosen default is removed, the default advances to the next ranked eligible action. Rewrite remains a first-level action near the front of the toolbar. Preferred primary order is `翻译 / 语法 / 改写 / 例句 / 收藏 / 发音`, with copy treated as a compact system utility.
- **Action order stability**: Language detection should not reorder the toolbar. Keep the same action order across English, Chinese, and mixed-language content; only the default action and availability state may change.
- **Language detection visibility**: Lingobar should not explicitly show language-detection labels in the MVP. The chosen default action and result title should communicate intent, and users can switch actions if the default is wrong.
- **Action priority**: The user-configurable ordering and prominence of built-in language actions and Custom Prompt Actions in Lingobar. Default priority should support the first-run reading workflow, but users can later prioritize actions such as rewrite, grammar, or their own custom actions for their habits.
- **Selection launcher**: The lightweight `划词浮标` that appears after text selection when enabled. It appears automatically after the selection stabilizes, gives up to five quick buttons for result-producing actions in the configured action-priority order, excluding save and collection actions, without showing AI results; choosing an action opens the full Lingobar for the selected text and immediately runs that action, while action-specific availability or errors are handled in Lingobar rather than by the launcher.
- **Editable selection text**: The editable copy of selected text inside Lingobar's selection workflow. Edits change the text Lingobar uses for language actions, mark existing results as stale until the user regenerates, and make the regenerated History record use the edited text; they do not modify the source app's original selection or imply write-back.
- **Mode hotkey**: A global shortcut that opens one Lingobar mode directly. Input mode and the selection workflow have separate mode hotkeys so users can choose whether Lingobar should read the current selection or open a blank input surface.
- **Write-back**: Returning generated text to the source app. The MVP should not make `插入当前 App` a primary action; use copy as the write-back path first, with direct replacement or insertion left for later versions.
- **Copy**: The compact system action that copies the current panel's primary result. Copy is the MVP write-back path; avoid treating it as direct insertion or replacement in the source app.
- **Contextual more action**: The third bottom action in the result panel. Avoid the generic label `继续展开`; use context-specific labels such as `解释更多` for translation, `继续拆解` for grammar, `更多版本` for rewrite, `更多例句` for examples, or `慢速播放` for pronunciation.
- **Result panel**: The expanded output area below the bar.
- **History**: The automatic, full record of every query the user has run, including the result snapshot and the action label used at the time. History is not curated by the user and its entries expire over time. It is distinct from `收藏` (a curated library) and from `保存` (a per-record retention state).
- **Recent selection history**: The most recent History record created from selected text rather than from Input mode. The selection workflow hotkey may reopen this record when no current selection is available; if none exists, Lingobar may open selection workflow with a default example text. Reopened selection history can be regenerated from its stored text.
- **Save**: The user-facing action labeled `保存`. It marks one whole History record so it no longer expires; it is a state on an existing record, not a new item, and does not move the record out of History. Use `保存` only for this retention action; do not use it as a synonym for `收藏`.
- **Collection**: The local place for the fragments the user has hand-picked. User-facing copy should call this area `收藏`; avoid abstract names such as `表达库`. Collection holds curated, typed fragments (see Collected item type), which distinguishes it from History (a full auto log) and from `保存` (retained whole records).
- **Collect**: The user action labeled `收藏` of hand-picking a fragment (a word, phrase, sentence, example, or generated result) out of a panel into the collection as its own typed item. This is a deliberate curation action on a fragment, distinct from `保存`, which retains a whole History record. Avoid `收录` for this action.
- **Collected item type**: The source-based type label for a collected item, such as `文本` for directly collected selected text, `英文` for a rewrite result, `例句` for an example, `句型` for a grammar pattern, or `短语` for a phrase or collocation.
- **Default collect target**: The item Lingobar collects when the user presses `收藏`. Collection follows the current content panel rather than always collecting the original selection: translation collects a key English expression or source text, rewrite collects the primary rewritten sentence, examples collect the highlighted or first example, grammar view collects the reusable sentence pattern, and a Custom Prompt Action collects its structured result's default collection item. Directly collecting the original selection should be a separate lightweight affordance such as `收藏原文`.
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
