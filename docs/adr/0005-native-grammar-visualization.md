# Render grammar visualization natively

Lingobar should implement the grammar visualization as native SwiftUI/AppKit drawing while using the HTML mockup as the visual specification. Pixel-level fidelity matters, but the grammar surface still belongs inside the native floating Lingobar experience with shared keyboard handling, copy and collection behavior, setup gating, and result state.

**Considered Options**

- Embed the mockup renderer in `WKWebView`: rejected because it would introduce a second UI runtime inside the floating panel and complicate focus, selection, clipboard, and native state handoff.
- Rebuild the mockup natively with custom SwiftUI/AppKit drawing: accepted because it preserves the app's native interaction model while allowing the visual layout, colors, tabs, diagrams, and grammar sections to match the mockup closely.

