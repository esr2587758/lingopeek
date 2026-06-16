# Require AI for language results

Lingobar MVP uses AI as the required engine for language results rather than a local-first or local-fallback strategy. This keeps translation, grammar, rewrite, examples, and pronunciation guidance aligned with the product promise of natural language understanding and expression; incomplete setup gates Lingobar's language features instead of returning user-facing template results.

**Considered Options**

- Local-first with AI enhancement: rejected because template results would make the product feel complete while failing the intended quality bar.
- AI-only: accepted because quality and natural expression matter more than offline availability for the self-use MVP.

**Consequences**

- The app needs a token / model settings surface before language actions can be considered complete.
- First use must include a setup gate when AI access or Accessibility permission is missing.
- Development fixtures may remain for tests and previews, but they are not the user-facing result path.
