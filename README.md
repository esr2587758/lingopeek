# LingoPeek

LingoPeek is a native macOS prototype for a selection-first language and AI bar.

Working positioning:

> 选中即解析，输入即生成。

The current codebase contains:

- [Product brief](docs/product-brief.md)
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

The app launches as a menu bar utility and shows the dark Lingobar panel. Select text in any app and press `Option-Command-L`; Lingobar captures the selected text into the panel and opens translation by default.

Move the floating panel by dragging the small header strip at the top of Lingobar.

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
```

DeepSeek connectivity can be verified without writing secrets to the repository:

```sh
DEEPSEEK_API_KEY="..." DEEPSEEK_MODEL="deepseek-v4-flash" swift run LingoPeekAIProbe
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
