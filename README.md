# LingoPeek

LingoPeek is a native macOS prototype for a selection-first language bar.

Working positioning:

> 选中即理解，输入即改写。

The current codebase contains:

- [Product brief](docs/product-brief.md)
- [Interaction guide](docs/interaction-guide.md)
- [Lingobar prototype](designs/lingobar-product/Lingobar Prototype.html)
- Native macOS app built with Swift, SwiftUI, and AppKit.

## Native App

Build:

```sh
swift build --product LingoPeek
```

Run:

```sh
swift run LingoPeek
```

Package an unsigned local `.app` bundle:

```sh
scripts/package_app.sh
```

The package is written to `dist/LingoPeek.zip`. GitHub Actions runs the same packaging script on every push and uploads the zip from the workflow run's artifacts. This package is ad-hoc signed, which costs nothing and fixes local bundle integrity checks, but it is not Apple Developer ID signed or notarized.

If macOS blocks a downloaded artifact on first launch, remove the download quarantine from the extracted app and then open it again:

```sh
xattr -dr com.apple.quarantine ~/Downloads/LingoPeek.app
```

The app launches as a menu bar utility and shows the dark Lingobar panel. Select text in any app and press `Option-Command-L`; Lingobar captures the selected text into the panel and opens translation by default.

Move the floating panel by dragging the small header strip at the top of Lingobar.

If Accessibility shows `LingoPeek` as enabled in System Settings but the app still says permission is missing, remove the old `LingoPeek` row from System Settings → Privacy & Security → Accessibility, quit LingoPeek, reopen the current `.app`, then add/enable it again. Local packages are ad-hoc signed, so rebuilding or replacing `LingoPeek.app` can change the code-signing identity that macOS TCC grants.

Open settings from the menu bar item:

```text
L → Settings...
```

AI responses are enabled by environment variables:

```sh
DEEPSEEK_API_KEY="..." DEEPSEEK_MODEL="deepseek-v4-flash" swift run LingoPeek
```

Without `DEEPSEEK_API_KEY`, the app uses deterministic local fallback content so the UI still works.

You can also fill DeepSeek Base URL, model, and API key in Settings. Environment variables still take priority when present.

## Verification

This machine's Command Line Tools installation does not provide `XCTest` or Swift Testing modules, so the repo uses a zero-dependency Swift executable check suite:

```sh
swift run LingoPeekCoreChecks
swift run LingoPeekGrammarUIChecks
```

DeepSeek connectivity can be verified without writing secrets to the repository:

```sh
DEEPSEEK_API_KEY="..." DEEPSEEK_MODEL="deepseek-v4-flash" swift run LingoPeekAIProbe
```

The grammar panel can be launched with deterministic long-sentence fixtures:

```sh
LINGOPEEK_GRAMMAR_FIXTURE=1 LINGOPEEK_GRAMMAR_FIXTURE_ID=policy-incentives swift run LingoPeek
LINGOPEEK_GRAMMAR_FIXTURE=1 LINGOPEEK_GRAMMAR_FIXTURE_ID=engineering-redesign swift run LingoPeek
```

## Design Preview

Serve the `designs` directory and open the prototype:

```sh
python3 -m http.server 4311 --directory designs
```

Then visit:

```text
http://localhost:4311/lingobar-product/Lingobar%20Prototype.html
```
