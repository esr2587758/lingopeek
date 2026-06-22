# Use a grammar-specific structured result

Grammar view needs a richer result shape than the generic Lingobar rows because grammar analysis contains source text, Chinese meaning, sentence chunks, visual breakdown views, reusable patterns, collocations, phrases, and grammar points. Lingobar should keep generic structured results for simpler language actions, but grammar results should use a dedicated structure so the AI contract and SwiftUI renderer can stay explicit instead of squeezing visual grammar content into flat rows.

**Considered Options**

- Reuse generic `rows/chips/summary`: rejected because it would make the grammar renderer brittle and leave too much meaning implicit in row labels.
- Dedicated grammar structure: accepted because the grammar mockup is a multi-section learning surface rather than a simple text result.

