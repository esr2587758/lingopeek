# Project Research: Features

## Table Stakes

- **Unified Hub navigation**: Sidebar with `收藏`, `历史`, and `设置`, grouped as `我的内容` and `应用`.
- **Collection list**: Search, type filters, item cards, source/time metadata, type tags, copy, delete, pronunciation/copy/relaunch affordances, and detail pane.
- **History list**: Search, action filters, item cards with action badges, saved status, transfer-to-collection affordance, clear-history affordance, and detail pane.
- **Settings inside Hub**: Subnav for `通用`, `AI 服务`, `权限`, `划词与唤起`, `语言动作`, `收藏`, and `关于`, backed by existing settings persistence.
- **Setup-gate status**: Sidebar footer shows `已就绪` or `需完成必填项` from AI and Accessibility state.
- **Toast feedback**: Short native feedback for copy, delete, save, settings changes, and relaunch actions.
- **Keyboard/window behavior**: Escape and Command-W close the Hub; header/side header drag regions move the borderless window.

## Differentiators

- **Selection-first continuity**: History relaunch can reopen a prior item in the floating Lingobar workflow rather than making the Hub a separate content app.
- **Real language-memory storage**: Collection and history are not mock screens; they reflect local language-learning activity.
- **Native settings plus library**: One management window replaces disconnected settings, making Lingobar feel like a complete macOS tool.
- **Design source parity**: The Hub should feel recognizably identical to the HTML prototype while remaining native.

## Anti-Features

- **No account system or sync**: Avoid broadening storage to network concerns.
- **No general document library**: Collection/history are language material, not arbitrary notes.
- **No always-on monitoring**: History should record explicit Lingobar actions, not passive background reading.
- **No microphone permission**: Voice input remains disabled/out of scope for MVP.
- **No source-app mutation from Hub**: Keep copy/relaunch instead of direct insertion.

## Complexity Notes

- The visual surface is medium-to-high complexity because it combines a custom borderless window, sidebar, filters, cards, detail pane, settings subnav, and multiple control styles.
- Real history persistence is the main scope expansion beyond visual cloning.
- Settings migration risk is moderate because replacing entry points should not remove existing settings behavior.
