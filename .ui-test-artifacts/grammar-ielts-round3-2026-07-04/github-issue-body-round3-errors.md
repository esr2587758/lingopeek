## Summary

Checked a third batch of 10 IELTS Academic Reading long sentences. Only the confirmed incorrect Grammar view result is listed here.

This batch found one grammar panel schema/decode failure.

## Environment

- App: local debug build, `.build/arm64-apple-macosx/debug/LingoPeek`
- Mode: Grammar (`语法`) via `LINGOPEEK_UI_TEST_SELECTION`
- Run artifact directory: `/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-round3-2026-07-04`
- Full run result: `/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-round3-2026-07-04/run-results-window.json`

## Incorrect Sentence

### Grammar panel schema/decode failure

Sentence:

> The staggering expenses involved in a successful Olympic bid are often assumed to be easily mitigated by tourist revenues and an increase in local employment, but more often than not host cities are short changed and their taxpayers for generations to come are left settling the debt.

Screenshot:

`/Users/lancer/app/LingoPeek/.ui-test-artifacts/grammar-ielts-round3-2026-07-04/lingopeek-03.png`

Observed:

- UI shows: `AI 返回结构不符合语法面板，请重试。`
- Metrics show `event: failure`, `status: 格式错误`.
- Metrics error:

```text
dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: "No JSON object found in AI response", underlyingError: nil))
```

Expected:

- Grammar view should return a structured parse instead of failing the panel schema.
- A reasonable parse should handle the passive main clause before `but`, then the coordinated second half with `host cities are short changed` and `their taxpayers ... are left settling the debt`.

## Notes

- The other 9 sampled sentences were checked and are intentionally not included because I did not find an objective grammar-parse error in those results.
- The screenshot referenced above is a LingoPeek panel screenshot, not a webpage screenshot.
