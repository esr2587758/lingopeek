# Lingobar 语法解析界面 — UX 还原规格（面向 SwiftUI）

> 来源：`designs/lingobar-grammar-viz/`（HTML/CSS 实现）
> 用途：交给 AI 用 SwiftUI 还原为原生 macOS 界面。
> 单位约定：CSS 的 `px` 在此 **1:1 当作 SwiftUI 的点(pt)**。
> 配色体系：深色玻璃，与 `lingobar-settings-spec.md` 同一套 `LB` token。成分另有一组**角色色板**。
> 本界面是「语法」动作展开后的浮层面板：顶部 pill + 主面板（样本句 → 视图切换 → 可视化区 → 可复用句型 → 知识两栏 → 底部操作）。

---

## 0. Token（沿用 + 角色色板）

基础 token 复用 `lingobar-settings-spec.md` 的 `enum LB`（accent `#6E8BFF`、glass、hairline、text/text2/text3、chip 等）。新增：

```swift
extension LB {
  // 阅读字体（正文/句子，区别于等宽）
  static let read = Font.system(.body, design: .default) // -apple-system / PingFang SC

  // 成分角色色板（句法成分 → 色相）。每个角色有实色 color + 半透明高亮 hl。
  enum Role: String, CaseIterable {
    case subject, predicate, object, attr, appos, adv, conj
    var zh: String {
      switch self {
      case .subject: "主语"; case .predicate: "谓语"; case .object: "宾语"
      case .attr: "定语"; case .appos: "同位语"; case .adv: "状语"; case .conj: "连接词"
      }
    }
    var color: Color {
      switch self {
      case .subject:   Color(hex: 0x6E8BFF)
      case .predicate: Color(hex: 0x8A7DFF)
      case .object:    Color(hex: 0x4FB8C9)
      case .attr:      Color(hex: 0xE0915C)
      case .adv:       Color(hex: 0x5BBF8A)
      case .appos:     Color(hex: 0xD6789F)
      case .conj:      Color(hex: 0xB6BCC8)
      }
    }
    var hl: Color { color.opacity(0.22) }   // conj 用 0.20
  }
}
```

> 角色色板是整个界面的视觉主线：6 个可视化视图、知识卡的边条、语序对照的色块，全部用同一套角色色，保证「同一成分到处同色」。

圆角层级：pill 13 / 面板 16 / 卡片 11–12 / 行内 8–9 / 徽章/色块 6–8 / 序号圆点圆形。
等宽字体 `LB.mono`：用于固定搭配短语、可复用句型、依存/语序的编号、动词标注。

---

## 1. 窗口结构

浮层不是实体窗口，是「pill + 面板」竖向堆叠，水平居中。

| 元素 | 值 |
|---|---|
| 容器 `.gwin` | 宽 **720**，top 64，水平居中，VStack spacing **8** |
| 高度 | `视口高 - 110`，上限 **800**；超出在面板内滚动 |
| 入场动画 | 0.26s，opacity 0→1 + Y 位移 8→0，曲线 `(0.22,0.61,0.36,1)` |

### 1.1 顶部 pill（标题条）
- HStack，padding `9 10 9 14`，圆角 13，背景 `LB.glass` + 玻璃模糊，1pt `hairline`
- 左：图标块 30×30 圆角 8（底 `accentWeak`，图标 `accentText` 16）+ 标题列
  - 标题「语法解析」14.5 / 600 / `text`
  - 副标「长难句 · 成分 · 搭配 · 语法点」11 / `text3`
- 右：关闭按钮 28×28 圆角 7，图标 16 `text3`，hover `chipHover`

### 1.2 主面板 `.g-panel`
- 圆角 16，背景 `LB.glass` + `blur(30) saturate(155%)`，1pt `hairline`，阴影同窗口规格
- **竖向 flex 容器 + 内部滚动**。⚠️ 关键：所有直接子块必须 `flex: none`（SwiftUI 里就是 VStack 自然高度 + 外层 ScrollView），否则内容超高时会被压缩重叠。
- 子块顺序：样本句 → 视图切换 tab → 可视化区 → 可复用句型 → 知识两栏 → 底部操作；每块之间 1pt `hairline` 分隔。

---

## 2. 样本句区 `.g-sentence`
- padding `18 20 14`，底部 1pt `hairline`
- 英文原句：19 / 500 / `text` / `LB.read`，行高 1.55
- 中文译文：13.5 / `text2`，上间距 8，行高 1.7

样本句（覆盖前置/后置定语、同位语从句、被动、状语从句）：
> The findings published last year call into question long-held assumptions that memory is consolidated while we sleep.

---

## 3. 视图切换 Tab `.g-viewtabs`
- HStack 可换行，gap 6，padding `12 16`，底部 1pt `hairline`
- 单 tab：图标 15 + 文字 12.5/500，padding `7 12`，圆角 9，1pt `hairline` 边框
  - hover：背景 `chip` + `text`
  - **选中**：背景 `accentWeak` + `accentText`，边框透明，字重 600
- 六个：成分标注 / 依存关系 / 层次结构 / 主干提取 / 时态语态 / 语序对照
- SwiftUI：`@State var view` 驱动；tab 用 ScrollView(.horizontal) 或 flexible wrap。

可视化区 `.g-viz`：padding `16 20`，底部 1pt `hairline`，min-height 150。下面逐视图说明。

---

## 4. 视图一：成分标注（含词级下钻）

### 4.1 角色图例 `.gx-legend`（成分/依存视图顶部）
- HStack 换行，gap 12；每项：9×9 圆角 3 的色点（角色色）+ 11.5 文字 `text2`
- 7 个角色全列；hover 某项时其余 `opacity .35`（联动）

### 4.2 标注句 `.gx-annot-sentence`
- 18 / `LB.read`，行高 **2.4**（给标签和下边框留空间）
- 每个成分块 `.gx-chunk`：内联，padding `3 5`，圆角 6，右距 2
  - 背景 = 角色 `hl`，底部 2pt 角色实色下划线（`box-shadow: inset 0 -2px 0`）
  - **悬停**：浮出成分标签（角色色实底白字小胶囊，9pt，位于块上方 -9）
  - **dim 态**（hover 其它角色时）：`opacity .32`
  - **点击**：展开/收起该成分对应的词级面板（下方 notes 里同步高亮 `data-open`）
- 提示行 `.gx-annot-hint`：11 / `text3`，上间距 14，文案「点击任意成分，展开词性与形态 ↓」

### 4.3 成分说明 + 词级下钻 `.gx-annot-notes`
- 上间距 22，竖列 gap 9
- 每条 `.gx-note`：左 3pt 角色色竖条 + 主体
  - 标题行（可点）：角色标签（11/600 角色色）+ 英文成分文本（13.5 `text`）+ 右侧折叠箭头（chevronRight，展开转 90°）
  - 中文说明：12 / `text3`，行高 1.55
  - **词级面板**（点击展开，0.18s 淡入下滑）：圆角 9，背景 `black .18`，padding `9 10`
    - 每词一行 `.gx-word`：Grid 三列 `[词 minmax(80)] [词性 auto] [屈折说明 1fr]`，gap 10
      - 词：13.5 / 500 / `read`；词性：11/600 角色色；屈折说明：11.5 `text3`
    - 例：`The | 限定词 | 定冠词，特指`；`findings | 名词 | 复数(-s)，find 的名词化`

---

## 5. 视图二：依存关系（SVG 弧线）

- 容器 `.gx-dep`，相对定位。上方 SVG 画弧，下方词块行。
- **词块行** `.gx-dep-tokens`：HStack 换行 gap 6；块 `.gx-dep-tok` padding `5 9` 圆角 7，背景 `chip`，底部 2pt 角色色下划线。
- **弧线（SVG，在词块上方）**：高度区 ~90。每条依存：
  - 三次贝塞尔从 from 块中心拱到 to 块中心；`lift = min(20 + 跨度*0.22, 74)`
  - 描边 = from 块的角色色，1.6pt，透明度 .85
  - 终点小三角箭头（指向基线）
  - 弧顶中央放关系标签：圆角胶囊（底 `#1B1D27`，角色色描边 .4），文字 10.5 角色色
  - dim 态透明度 .2–.3
- 依存样例：主谓（谓→主）、后置修饰（主→分词定语）、动宾（谓→宾）、同位（宾→同位语从句）
- **SwiftUI 实现**：用 `Canvas` 或 `Path` 画弧；词块位置先用 `GeometryReader`/anchor preference 测量再连线。比 settings 复杂，是本界面技术重点。

---

## 6. 视图三：层次结构（嵌套树）

- `.gx-tree`，递归节点 `.gx-tree-node`，子级 `marginLeft 18`
- 行 `.gx-tree-row`：3pt×16 角色色竖条 + 角色标签（11/600 角色色，min-width 76）+ 英文文本（13.5 `text`），padding 上下 6
- 子级容器：左侧 1pt 虚线 `hairlineStrong`，padding-left 4
- 层级示例：主句 →（主语→后置定语分词）（谓语）（宾语→同位语从句→从句主/谓被动/时间状语从句→其主谓）
- SwiftUI：递归 `View`，缩进用 leading padding，虚线用 `overlay` 画 `Rectangle().stroke(style: .init(dash:[2]))`。

---

## 7. 视图四：主干提取

- 骨架 `.gx-trunk-core`：HStack 换行 gap 8，19pt。每块 padding `5 11` 圆角 9，背景角色 `hl`，**1pt 角色色描边**（inset）
- 中文骨架 `.gx-trunk-zh`：14 / `text2`，上间距 12
- 省略项 `.gx-trunk-dropped`：上间距 16，HStack 换行 gap 7
  - 标签「已省略的修饰成分」11 `text3`
  - 每个 chip：12 `text3`，padding `4 10`，圆角 7，背景 `chip`，**删除线**（`text3` 色）
- 示例骨架：The findings · call into question · assumptions；省略：published last year（后置定语·分词）/ long-held（前置定语）/ that 从句（同位语从句）

---

## 8. 视图五：时态 · 语态 · 语气 ⭐新增

`.gx-tense`：竖列 gap 10，每个分句一张卡 `.gx-tense-card`：
- padding `12 13`，圆角 12，背景 `chip`，**左 3pt 边条**：主动 = `accent`，被动 = `#4FB8C9`
- 头部 `.gx-tense-head`：作用域标签（11/600 `text3`，如「主句」「同位语从句」）+ 动词（等宽 14 `text`）
- 徽章组 `.gx-tense-badges`（上间距 9，HStack 换行 gap 6），每徽章 11/600 padding `3 9` 圆角 6：
  - 时态徽章 `t-tense`：底 `rgba(138,125,255,.18)` 字 `#B3AAFF`
  - 体徽章 / 语气徽章：底 `chipHover` 字 `text2`
  - 语态徽章 `t-voice`：被动时底 `rgba(79,184,201,.2)` 字 `#7FD6E3`（高亮）；主动用默认灰
- **施受关系** `.gx-svo`（上间距 11，HStack 换行 gap 8）：
  - 施动者节点 `n-agent`：底 `rgba(110,139,255,.18)` 字 `#B3C0FF`
  - 箭头 `.gx-svo-arrow`：arrowRight 14 + 动词（等宽 11 `text2`）
  - 受动者节点 `n-recv`：底 `rgba(79,184,201,.18)` 字 `#8FDCE8`；无宾语时 `n-none` 灰底「（无宾语）」
  - 节点 12.5，padding `5 11`，圆角 8
- 解释 `.gx-tense-why`：12 / `text3`，行高 1.6，上间距 10
- 三张卡示例：主句(现在时·主动·陈述) / 同位语从句(现在时·**被动**·陈述，施动者省略) / 时间状语从句(现在时·主动)

> 这一视图是给中文母语者讲清「时态承载的客观性 + 被动隐藏施动者 + 施受真实关系」，被动卡的青色边条和高亮徽章是视觉重点。

---

## 9. 视图六：中英语序对照 ⭐新增（最高价值）

`.gx-order`：竖列 gap 4。
- **英文行 / 中文行** `.gx-order-row`：HStack 顶对齐 gap 12
  - 行首语言标签 `.gx-order-lang`：宽 56，11/600 `text3`，padding-top 7（「英文语序」「中文语序」）
  - 内容 `.gx-order-line`：HStack 换行 gap 6，每段 `.gx-order-seg`：
    - padding `5 9 5 7`，圆角 8，背景角色 `hl`，底部 2pt 角色色下划线（inset）
    - 段首序号圆点 `.gx-order-num`：16×16 圆，角色实色底，深色字（`#0D0E12`）10/700 等宽
    - **被移动段**（后置修饰）`data-moved`：改用 **1.5pt 角色色全描边**（替代下划线），强调「这块被搬动了」
- **映射行** `.gx-order-mapline`：arrowDown 16 + 「后置修饰前移」11.5 `accentText`，padding-left 68（对齐内容列）
- **说明** `.gx-order-note`：12 `text2` 行高 1.6，padding `10 12` 圆角 9，底 `rgba(224,145,92,.1)` + 橙色描边；前置一个描边小色块图例代表「被移动」
- 数据：英文序 `①②③④⑤`，中文重排 `②①⑤④③`（后置定语②、同位语从句⑤前移）

> SwiftUI：两行各自 wrap 布局；同一序号在两行用同色，靠颜色 + 数字让用户眼睛自己连线。被移动段用描边而非填充区分。

---

## 10. 可复用句型 `.g-pattern`
- padding `13 20`，底部 1pt `hairline`，背景 `rgba(110,139,255,.05)`
- 标签「可复用句型」10.5/600 大写 letter-spacing .06em `accentText`
- 英文模板：14.5 等宽 `text`，上间距 5
- 中文：12.5 `text2`

---

## 11. 知识两栏 `.g-knowledge`
- Grid 2 列 gap 16，padding `16 20`，底部 1pt `hairline`
- 栏标题 `.g-col-head`：图标 15(`accentText`) + 12/600 `text2`，下间距 10；次级标题加 margin-top 16

### 11.1 固定搭配卡 `.gx-colloc`（左栏）
- padding `11 12`，圆角 11，背景 `chip`，下间距 9
- 头：短语（等宽 14/600 `accentText`）+ 词性（10.5 斜体 `text3`）+ 右侧发音按钮 24×24 圆角 6（底 `chipHover`，hover 变 `accent` 白字）
- 释义 13 `text`（上 6）/ 用法 11.5 `text3`（上 4）
- 例句 `.gx-colloc-eg`：12.5 `text2`，padding `6 9` 圆角 7 底 `white .03`；前缀「e.g.」斜体 `accentText`

### 11.2 常见词组 chips `.g-phrases`（左栏下半）
- HStack 换行 gap 7；chip 竖排：英文 13 `text` + 中文 10.5 `text3`，padding `6 10` 圆角 8 背景 `chip`，hover `chipHover`

### 11.3 语法点卡 `.gx-point`（右栏）
- padding `11 12 11 14`，圆角 11，背景 `chip`，下间距 9；**左 3pt 竖条**用每卡自带 `color`
- 头：标签胶囊（10/600 白字，底=该卡色，padding `2 7` 圆角 5）+ 标题 13/600 `text`
- 正文 12 `text2` 行高 1.6
- 四类示例：从句（同位语vs定语）/ 语态（被动表客观）/ 修饰（前置vs后置）/ 非谓语（过去分词作定语）

---

## 12. 底部操作 `.g-foot`
- HStack gap 6，padding `11 16 13`
- 按钮 `.g-foot-btn`：高 32，padding `0 13`，圆角 8，图标 15 + 12.5/500，底 `chip` 字 `text2`，hover `chipHover`+`text`
  - 复制 / 收藏句型（左），spacer，举一反三（右，`primary`：底 `accent` 白字）

Toast：同 settings 规格（白底深字胶囊，底部居中 40，0.2s 上移淡入）。

---

## 13. 还原要点（给 Swift 工程）

1. **角色色是全局主线**：把 `LB.Role` 做成枚举，任何成分块/树节点/语序段/施受节点都从它取 `color`/`hl`。「同一成分到处同色」是这套设计的灵魂。
2. **面板用 ScrollView + VStack 自然高度**：切忌让子块参与 flex 压缩（CSS 这里踩过坑，靠 `flex:none` 修复）。SwiftUI 默认 VStack 不压缩，但若用 `.frame(maxHeight:)` 要注意给内容 ScrollView。
3. **依存弧线是技术重点**：词块位置用 `GeometryReader` + `anchorPreference` 收集，再在 overlay 的 `Canvas` 里画三次贝塞尔 + 箭头 + 标签。其余视图都是布局，无需测量。
4. **下钻是局部展开**：成分标注的词级面板是「点击成分 → 该成分说明下展开词表」，用 `@State var openChunk: String?` 控制，配 0.18s 过渡。
5. **语序对照靠颜色+序号连线**：不画连线，两行同序号同色，让用户视觉自连；被移动段用描边区别于填充。这是低成本高表达的取舍。
6. **被动语态的视觉强调**：时态卡左边条 + 语态徽章在被动时切到青色（`#4FB8C9` 系），是针对中文母语者的刻意高亮，别做成和主动一样。
7. **数据结构即契约**：`Role` 枚举、`Chunk{role,text,note,tokens[]}`、`Dep{from,to,label}`、递归 `TreeNode`、`TenseClause{tense,voice,mood,svo}`、`OrderSeg{id,role,zhPos,moved}`——AI 生成时先定这些 model，视图只是渲染器。

---

## 附：视图 → 数据 → 关键控件 速查

| 视图 | 数据 | 关键控件 |
|---|---|---|
| 成分标注 | CHUNKS（含 tokens） | 内联色块 + 悬停标签 + 点击下钻词表 |
| 依存关系 | DEPS + CHUNKS | Canvas 贝塞尔弧 + 箭头 + 标签胶囊 |
| 层次结构 | TREE（递归） | 缩进递归行 + 虚线竖轨 |
| 主干提取 | TRUNK | 描边色块骨架 + 删除线 chip |
| 时态语态 | TENSE.clauses | 卡片 + 徽章组 + 施受三节点 |
| 语序对照 | ORDER | 双行 wrap 色段 + 序号圆点 + 描边标移动 |
| 可复用句型 | PATTERN | 等宽模板行 |
| 知识两栏 | COLLOCATIONS / PHRASES / GRAMMAR_POINTS | 搭配卡 / chips / 带色条语法点卡 |
