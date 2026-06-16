# Lingobar 设置界面 — UX 还原规格（面向 SwiftUI）

> 来源：`designs/lingobar-settings/`（HTML/CSS 实现）
> 用途：交给 AI 用 SwiftUI 还原为原生 macOS 界面。
> 单位约定：CSS 的 `px` 在此 **1:1 当作 SwiftUI 的点(pt)**。颜色给出 RGBA 与 SwiftUI `Color` 写法。
> 配色体系：深色玻璃。深底上的文字/描边/填充大多是「白色 + 不透明度」，因此能自适应任意深背景。

---

## 0. SwiftUI 设计 Token（先抄这段）

```swift
import SwiftUI

enum LB {
  // 强调色
  static let accent      = Color(red: 110/255, green: 139/255, blue: 255/255)               // #6E8BFF
  static let accent2     = Color(red: 138/255, green: 125/255, blue: 255/255)               // #8A7DFF
  static let accentText  = Color(red: 170/255, green: 182/255, blue: 255/255)               // #AAB6FF
  static let accentWeak  = Color(red: 110/255, green: 139/255, blue: 255/255).opacity(0.16)

  // 文字（白 + 透明度）
  static let text   = Color.white.opacity(0.95)
  static let text2  = Color.white.opacity(0.60)
  static let text3  = Color.white.opacity(0.38)

  // 表面 / 描边 / 填充
  static let glass        = Color(red: 28/255, green: 30/255, blue: 40/255).opacity(0.82)   // 窗口玻璃
  static let hairline     = Color.white.opacity(0.09)
  static let hairlineStrong = Color.white.opacity(0.15)
  static let chip         = Color.white.opacity(0.06)
  static let chipHover    = Color.white.opacity(0.11)
  static let blackField   = Color.black.opacity(0.22)   // 分段控件凹槽

  // 状态色
  static let ok   = Color(red: 79/255,  green: 208/255, blue: 160/255)  // #4FD0A0
  static let warn = Color(red: 224/255, green: 145/255, blue: 92/255)   // #E0915C

  // 圆角
  static let radiusWindow: CGFloat = 16
  static let radiusGroup:  CGFloat = 12
  static let radiusCtrl:   CGFloat = 8     // 输入/下拉/按钮
  static let radiusChip:   CGFloat = 7     // 分段项

  // 字体
  static let mono = Font.system(.body, design: .monospaced)  // 近似 Space Grotesk（API Key / 快捷键 / 序号）
}
```

> 玻璃材质：窗口背景用 `LB.glass` 叠加 `.background(.ultraThinMaterial)` 或 `NSVisualEffectView`（material `.hudWindow` / `.underWindowBackground`）实现 `blur(32px) saturate(155%)` 的近似。CSS 原值：`backdrop-filter: blur(32px) saturate(155%)`。

阴影（窗口）：两层
```swift
.shadow(color: .black.opacity(0.75), radius: 35, x: 0, y: 30)   // 0 30px 70px -18px rgba(0,0,0,.75)
// 外加 1px 描边高光：.overlay(RoundedRectangle(...).stroke(Color.white.opacity(0.06), lineWidth: 1))
```

动画曲线：`cubic-bezier(0.22, 0.61, 0.36, 1)` → SwiftUI 近似 `.timingCurve(0.22, 0.61, 0.36, 1, duration: 0.18)`。通用过渡时长 `0.14s`，开关 `0.18s`。

---

## 1. 窗口与整体布局

| 元素 | 值 |
|---|---|
| 窗口宽 | **760** |
| 窗口高 | `calc(100vh - 140)`，上限 **680**（即固定 760×680 的设置窗） |
| 圆角 | 16 |
| 背景 | `LB.glass` + 玻璃模糊 |
| 描边 | 1pt `LB.hairline` |
| 布局 | 左右两栏 HStack：左导航固定宽 **212**，右内容 flex 填充 |
| 左右分隔 | 1pt 垂直 `LB.hairline` |

菜单栏(演示外壳，原生 app 不需要)：高 26，可忽略。

---

## 2. 左侧导航栏（宽 212）

容器：padding `14 10`（上下 14 / 左右 10），项间距 `2`，可滚动。

### 2.1 标题 `设置`
- 字号 15 / 字重 600 / `LB.text`，左侧齿轮图标 18，gap 8，padding `2 8 12`

### 2.2 导航项（7 个）
布局：HStack，gap 11，padding `9 10`，圆角 10。

| 状态 | 背景 | 文字 | 图标底色 |
|---|---|---|---|
| 静态 | 透明 | `text2` | `chip` |
| hover | `chip` | `text` | `chip` |
| 选中 | `accentWeak` | `accentText` | `rgba(110,139,255,.2)` |

- **图标容器**：26×26，圆角 7，居中，内图标 17
- **主名称**：13.5 / 字重 600；若为必填分区(AI/权限)且未完成，名称后跟 6×6 橙点 `warn`
- **副标题**：11 / `text3`（选中时 `accentText` opacity .7）

七项依次：
| id | 图标 | 名称 | 副标题 | 必填 |
|---|---|---|---|---|
| general | 齿轮 | 通用 | 启动与外观 | |
| ai | 闪电 | AI 服务 | 模型接入 | ✓ |
| permissions | 盾牌 | 权限 | 辅助功能 | ✓ |
| trigger | 光标 | 划词与唤起 | 如何呼出 | |
| actions | 滑块 | 语言动作 | 顺序与默认 | |
| collection | 收藏勾 | 收藏 | 收藏行为 | |
| about | info | 关于 | 版本信息 | |

### 2.3 底部状态条（setup gate）
- 贴底（`margin-top: auto`），padding `10 6 2`
- 胶囊：inline，gap 6，字号 11，padding `5 10`，圆角 8
- **未就绪**：背景 `rgba(224,145,92,.14)`，文字 `warn`，图标 alert，文案「需完成必填项」
- **已就绪**：背景 `rgba(79,208,160,.14)`，文字 `ok`，图标 check，文案「已就绪」
- 就绪条件：辅助功能已授权 **且** API Key 非空

---

## 3. 右侧内容区

### 3.1 头部 `.set-head`
- padding `18 22 14`，底部 1pt `hairline`
- 标题 18 / 字重 600 / `text`
- 副标题 12.5 / `text3` / 上间距 2

### 3.2 滚动区 `.set-scroll`
- padding `18 22 26`，纵向滚动

### 3.3 分组 `.st-group`
- 组间距：底部 22
- 组标题 `.st-group-title`：11 / 字重 600 / 大写 / letter-spacing `.07em` / `text3` / 下间距 9 / 左缩进 2
- 组主体 `.st-group-body`：圆角 12，背景 `chip`，`overflow: hidden`（行分隔线贴边）

### 3.4 设置行 `.st-row`
- HStack，gap 16，padding `13 15`，行间 1pt `hairline`（最后一行无）
- 左侧标签区(flex 1)：
  - 标题 13.5 / 字重 500 / `text`；必填项标题后跟 5×5 橙点
  - 说明 11.5 / `text3` / 上间距 3 / 行高 1.5
- 右侧控件区：flex none，居中

---

## 4. 控件逐个量化

### 4.1 开关 Toggle
| 属性 | 值 |
|---|---|
| 轨道 | 42 × 25，圆角 13 |
| 关背景 | `chipHover` |
| 开背景 | `accent` |
| 滑块 | 19×19 圆，白色，位移 `top 3 / left 3`，开启时 `translateX(17)` |
| 滑块阴影 | `0 2px 5px rgba(0,0,0,.35)` |
| 动画 | 0.18s ease |

```swift
// SwiftUI: 自定义 Toggle，开=LB.accent，关=LB.chipHover，knob 19pt 白圆
```

### 4.2 分段控件 Segmented
- 凹槽：padding 3，圆角 9，背景 `blackField`(黑 22%)
- 选项：字号 12.5，padding `5 12`，圆角 7
  - 静态文字 `text2`；hover `text`；**选中** 背景 `accent` + 白字
- 用于：默认动作（英文 `翻译/语法/改写/例句`、中文 `改写/翻译`）

### 4.3 下拉 Select
- 高 ~34（padding `7 30 7 12`），圆角 8，背景 `chipHover`，1pt `hairline` 边框
- 文字 13 / `text`；右侧 chevronDown 14 / `text3`，距右 9
- hover 边框转 `hairlineStrong`；聚焦无特殊
- 展开菜单项底色 `#20222C`

### 4.4 文本输入 TextField（含密文）
- 容器：min-width 220，圆角 8，背景 `chipHover`，1pt `hairline`，padding `0 4 0 11`
- 聚焦：边框转 `accent`
- input：字号 13 / `text`，padding 上下 8；占位 `text3`
- `data-mono` 时(API Key / Base URL)：等宽字体
- 密文：右侧「显示/隐藏」小按钮，11 / `text3`，padding `4 7`，圆角 6，hover `chip`

### 4.5 状态徽章 Badge
- inline，gap 5，字号 12 / 字重 600，padding `4 10`，圆角 7
- `ok`：背景 `rgba(79,208,160,.16)` + 文字 `ok`（含 check 图标 12）
- `muted`：背景 `chipHover` + 文字 `text3`（如「未启用」）

### 4.6 主按钮 Button.primary
- 字号 12.5 / 字重 600，padding `7 14`，圆角 8，背景 `accent`，白字
- hover `brightness(1.08)`（SwiftUI 用 opacity 0.92 或叠白近似）

### 4.7 快捷键 Hotkey
- 键帽 `kbd`：等宽 12，min-width 24，居中，padding `4 8`，圆角 6
- 背景 `chipHover`，1pt `hairline`，文字 `text`，底部阴影 `0 1px 0 rgba(0,0,0,.3)`
- 多键间距 4。示例：`⌥` `Space`

---

## 5. 复合组件

### 5.1 外观方案卡（通用页）
- 网格：2 列，gap 9，容器 padding 12
- 卡片：纵向，gap 7，padding 10，圆角 11，1pt `hairline` 边框
  - hover 背景 `chipHover`
  - **选中**：边框 `accent` + 背景 `accentWeak`
- 预览块：高 46，圆角 8，背景=方案主色，内嵌 inset 1px 暗描边
  - 强调条：左下 `left 10 / bottom 10`，36×8，圆角 4，色=方案强调色
- 名称 13 / 字重 600 / `text`，选中时右侧 check 13 `accentText`
- 描述 11 / `text3`

四套方案数据(预览主色 / 强调色)：
| id | 名称 | 描述 | 主色 | 强调 |
|---|---|---|---|---|
| glass | Tahoe 玻璃 | 系统浅玻璃·系统蓝 | `#F4F6F9` | `#0A84FF` |
| tool | 克制工具 | 深色·键盘优先 | `#1C1D24` | `#8B9BFF` |
| reader | 温暖阅读 | 暖色·衬线阅读 | `#FAF6EF` | `#C0673C` |
| brand | 品牌珊瑚 | 品牌色调 | `#1A1320` | `#FF7A59` |

### 5.2 可拖拽排序列表（语言动作页）
- 容器 padding 8，行间距 5
- 行：HStack，gap 11，padding `9 11`，圆角 9，背景 `rgba(255,255,255,.04)`，`cursor: grab`
  - hover 背景 `chipHover`
  - **拖拽悬停目标 `data-over`**：inset 1px `accent` 描边 + 背景 `accentWeak`
- 元素顺序：grip 把手(16, `text3`) → 序号(等宽 11, `text3`, 宽 14) → 图标容器(24×24, 圆角 6, 底 `chip`, 图标 `accentText`) → 标签(13.5 / 字重 500 / `text`) → 备注(靠右, 11 / `text3`, padding `2 8`, 圆角 6, 底 `chip`)
- 六个动作：翻译(备注「英文默认」)、语法(「仅英文」)、改写(「中文默认」)、例句、收藏、发音
- SwiftUI 实现：`List` + `.onMove`，或 `ForEach` + `.draggable`/`.dropDestination`

### 5.3 单选卡（收藏页：默认收藏目标）
- 卡片：HStack 顶对齐，gap 11，宽满，padding `13 15`，行间 1pt `hairline`
  - hover `chipHover`；**选中** `accentWeak`
- 单选点：17×17 圆，2pt 边框 `text3`(未选)/`accent`(选中)；选中时内部 inset 3 填 `accent`，上间距 2
- 文本：标题 13.5 / 字重 600 / `text`；描述 11.5 / `text3` / 行高 1.5
- 两项：`跟随当前面板`(说明：翻译收关键表达、改写收主句…) / `总是收原文`

### 5.4 Setup Gate 警示横幅（AI 页顶部，未就绪时）
- padding `11 14`，圆角 10，下间距 18
- 背景 `rgba(224,145,92,.13)`，1pt 边框 `rgba(224,145,92,.25)`，文字 `warn`
- alert 图标 16 + 文案 12.5 / 行高 1.5

### 5.5 关于页
- 居中 VStack，padding `30 20`，gap 5
- Logo：56×56，圆角 14，背景 `accentWeak`，图标 26 `accentText`，下间距 6
- 名称 18 / 字重 600；版本 12 / `text3` 等宽数字；描述 12.5 / `text2` 上间距 6
- 链接行：gap 18，上间距 14，链接 12.5 / `accentText`，hover 下划线

---

## 6. Toast（操作反馈）
- 居中底部 `bottom 56`，padding `8 15`，圆角 9，gap 7
- 背景 **纯白 `#FFFFFF`**，文字 `#1A1A1F` 12.5 / 字重 600，check 图标 14
- 阴影 `0 12px 30px -8px rgba(0,0,0,.5)`，入场 0.2s（上移淡入）

---

## 7. 还原要点（给 Swift 工程的提醒）

1. **配色「白叠透明」**：深底上的文字/描边/填充别用固定灰，用 `Color.white.opacity(...)`，与 token 表一致，换深背景自动适配。
2. **强调色实色 `#6E8BFF` 只用于**：主按钮、开关开启态、分段选中、单选填充、设置项选中图标底。其余选中态用弱底 `accentWeak` + 亮字 `accentText`。
3. **圆角层级**：窗口 16 → 分组卡 12 → 方案卡 11 → 行内控件 8 → 分段/键帽 7 → 单选点圆形。
4. **分组卡模式**：每个 section 由若干「组标题(小字大写) + 圆角卡(内部行分隔线)」堆叠，是整套设置的骨架。
5. **setup gate 是状态机**：`gateOk = accessibility授权 && apiKey非空`。它驱动三处 UI——左侧底部胶囊色/文案、导航项橙点、AI 页顶部横幅。Swift 里用一个 `@Published var gateOk` 派生即可。
6. **玻璃材质**：原生用 `NSVisualEffectView`（`.hudWindow` 或 `.underWindowBackground`）比纯色 + 模糊更贴近，再叠 `LB.glass` 调色。
7. **窗口固定 760×680**，不自适应高度，超出内容在右侧滚动区滚动。

---

## 附：分区 → 控件映射速查

| 分区 | 控件 |
|---|---|
| 通用 | 2× Toggle（开机启动/菜单栏）+ 4 张外观方案卡 |
| AI 服务 | (条件)警示横幅 + Select×2(服务商/模型) + 密文 TextField(API Key) + (条件)TextField(Base URL) |
| 权限 | Badge(辅助功能 已授权/按钮 去授权) + Badge(麦克风 未启用) + 脚注 |
| 划词与唤起 | Toggle×2(选区唤起/划词浮标) + Hotkey(⌥ Space) |
| 语言动作 | 拖拽排序列表(6 动作) + Segmented×2(英/中默认动作) |
| 收藏 | 单选卡×2(收藏目标) + Toggle(自动读剪贴板) |
| 关于 | Logo + 版本 + 链接 |
