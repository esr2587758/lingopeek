## Summary

Checked another batch of 10 IELTS Academic Reading long sentences. Only the confirmed incorrect Grammar view results are listed here.

This batch found:

- One copular sentence where predicative complements are rendered as objects.
- One fronted-complement / inverted copular sentence where core subject tokens are omitted from the component output.
- One long sentence that fails with a grammar panel schema/decode error.

## Environment

- App: local debug build, `.build/arm64-apple-macosx/debug/LingoPeek`
- Mode: Grammar (`语法`) via `LINGOPEEK_UI_TEST_SELECTION`
- Run artifact directory: `/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-round2-2026-07-04`
- Full run result: `/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-round2-2026-07-04/run-results-window.json`

## Incorrect Sentences

### 1. Predicate complement is rendered as object

Sentence:

> The feel good factor that most proponents of Olympic bids extol, and that was no doubt driving the approval rates of Parisians and Londoners for their cities' respective bids, can be an elusive phenomenon, and one that is tied to that nation's standing on the medal tables.

Screenshot:

`/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-round2-2026-07-04/lingopeek-05.png`

Observed:

- The main predicate is `can be`.
- The component output colors `an elusive phenomenon` and `one that is tied...` as object-like chunks.

Expected:

- `an elusive phenomenon` is a predicative complement after the copular verb `be`, not an object.
- `one that is tied...` is a coordinated predicative complement, not a second object.

### 2. Inverted copular structure drops core subject tokens

Sentence:

> Even more confounding than Manet's relaxed attention to detail, however, is the relationship in the painting between the activity in the mirrored reflection and that which we see in the unreflected foreground.

Screenshot:

`/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-round2-2026-07-04/lingopeek-08.png`

Observed:

- The inline component output shows `Even more confounding... however is in the painting in the mirrored reflection and that which...`.
- Core words from the subject noun phrase, especially `the relationship` and `the activity`, are missing from the component output.
- The fronted predicative phrase `Even more confounding...` is treated as an adverbial-style chunk rather than as the complement in an inverted copular clause.

Expected:

- The sentence should be treated as an inverted version of: `the relationship ... is even more confounding than ...`.
- The subject should include `the relationship in the painting between the activity ... and that which ...`.
- No source tokens should disappear from the component rendering.

### 3. Grammar panel schema/decode failure

Sentence:

> Davis was also frustrated by his perception that he had been overlooked by the music critics, who were hailing the success of his collaborators and descendants in the cool tradition, but who afforded him little credit for introducing the cool sound in the first place.

Screenshot:

`/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-round2-2026-07-04/lingopeek-09.png`

Observed:

- UI shows: `AI 返回结构不符合语法面板，请重试。`
- Metrics show `event: failure`, `status: 格式错误`.
- Metrics error:

```text
dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: "No JSON object found in AI response", underlyingError: nil))
```

Expected:

- Grammar view should return a structured parse.
- A reasonable parse should handle `that he had been overlooked...` as a content clause after `perception`, and the two coordinated `who...` relative clauses modifying `critics`.

## Notes

- The other 7 sampled sentences were checked and are intentionally not included because I did not find an objective grammar-parse error in those results.
- The screenshots referenced above are LingoPeek panel screenshots, not webpage screenshots.
