# Require structured AI results

Lingobar MVP should request structured JSON results from the AI provider instead of rendering arbitrary free text. The UI is a fixed language panel rather than a chat transcript, so translation, grammar, rewrite, examples, pronunciation, collection defaults, and contextual more actions need predictable fields to render stable cards and actions.

**Considered Options**

- Free-text responses parsed heuristically: rejected because small prompt drift would break UI rendering and collection behavior.
- Structured JSON responses: accepted because it keeps the floating panel predictable and makes parse failures explicit and recoverable.
