## Summary

From a 10-sentence IELTS Academic Reading grammar check sample, only the confirmed incorrect cases are listed here.

There are two failure modes:

- One long sentence returns no usable Grammar view because the AI response cannot be decoded into the grammar panel schema.
- Two relative-clause sentences duplicate a single relative pronoun in the colored component output, making the parsed sentence read as if the word appears twice.

## Environment

- App: local debug build, `.build/arm64-apple-macosx/debug/LingoPeek`
- Mode: Grammar (`语法`) via `LINGOPEEK_UI_TEST_SELECTION`
- Run artifact directory: `/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-2026-07-04`
- Full run result: `/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-2026-07-04/run-results-window.json`

## Incorrect Sentences

### 1. Grammar panel schema/decode failure

Sentence:

> Perpetually by-passing minor cities creates a cycle of disenfranchisement: these cities never get an injection of capital, they fail to become first-rate candidates, and they are constantly passed over in favour of more secure choices.

Screenshot:

`/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-2026-07-04/lingopeek-02.png`

Observed:

- UI shows: `AI 返回结构不符合语法面板，请重试。`
- Metrics show `event: failure`, `status: 格式错误`.
- Metrics error:

```text
dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: "No JSON object found in AI response", underlyingError: nil))
```

Expected:

- Grammar view should return a structured analysis instead of failing the panel schema.
- A reasonable parse should handle the first main clause before the colon and the three coordinated clauses after the colon.

### 2. Single relative pronoun `that` is rendered twice

Sentence:

> The convergence of fashion and high technology is leading to new kinds of fibres, fabrics and coatings that are imbuing clothing with equally wondrous powers.

Screenshot:

`/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-2026-07-04/lingopeek-07.png`

Observed:

- Original sentence has one `that`.
- Colored component output displays `... coatings that that are imbuing ...`.
- The detail list separately labels `that` as `关系代词` and also as `从句主语`, causing a duplicated token in the rendered sentence.

Expected:

- The relative pronoun should appear once in the inline component rendering.
- If `that` is both the relative marker and the subject of the relative clause, the UI/data model should represent that dual role without duplicating the surface token.

### 3. Single relative pronoun `which` is rendered twice

Sentence:

> These discoveries have led to the field known as neuroeconomics, which studies the brain's secrets to success in an economic environment that demands innovation and being able to do things differently from competitors.

Screenshot:

`/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-2026-07-04/lingopeek-10.png`

Observed:

- Original sentence has one `which`.
- Colored component output displays `... neuroeconomics, which which studies ...`.
- As above, the relative pronoun appears once as the relationship word and once as the relative-clause subject in the rendered component sequence.

Expected:

- The `which` token should appear once in the inline component rendering.
- The relative-clause subject role should not cause the sentence text to be duplicated.

## Notes

- The other 7 sampled IELTS sentences were checked and are intentionally not included here because I did not find an objective grammar-parse error in those results.
- The screenshots referenced above are LingoPeek panel screenshots, not webpage screenshots.
