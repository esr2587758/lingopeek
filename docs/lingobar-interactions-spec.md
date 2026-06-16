# Lingobar Interactions — 开发还原规格

> 来源：`designs/lingobar-interactions/Lingobar Interactions.html`
> 深色玻璃风格。所有数值直接取自源 CSS，单位 px（除非标注）。
> 颜色凡是 `rgba(255,255,255,a)` 都是「白色 + 透明度」，叠在深色背景上。

---

## 1. 设计 Token（全局变量）

### 配色
| Token | 值 | 用途 |
|---|---|---|
| `accent` | `#6E8BFF` | 主强调色（按钮、激活态、播放键） |
| `accent-2` | `#8A7DFF` | 次强调色（渐变终点、vseg 激活） |
| `accent-text` | `#AAB6FF` | 强调色文字（在深底上更亮） |
| `accent-weak` | `rgba(110,139,255,0.16)` | 强调色弱背景（激活 chip） |
| `glass` | `rgba(28,30,40,0.78)` | 主玻璃面板背景 |
| `glass-2` | `rgba(40,43,56,0.70)` | 次级玻璃（径向花瓣） |
| `hairline` | `rgba(255,255,255,0.09)` | 描边/分隔线 |
| `hairline-strong` | `rgba(255,255,255,0.15)` | 强描边 |
| `text` | `rgba(255,255,255,0.95)` | 主文字 |
| `text-2` | `rgba(255,255,255,0.60)` | 次文字 |
| `text-3` | `rgba(255,255,255,0.38)` | 三级文字/占位 |
| `chip` | `rgba(255,255,255,0.06)` | chip/按钮静态背景 |
| `chip-hover` | `rgba(255,255,255,0.11)` | chip/按钮 hover 背景 |

### 阴影
| Token | 值 |
|---|---|
| `shadow`（标准面板） | `0 0 0 1px rgba(255,255,255,0.06), 0 30px 70px -18px rgba(0,0,0,0.75)` |
| Pin 固定态 | `0 0 0 1px #6E8BFF, 0 24px 60px -18px rgba(0,0,0,0.7)` |
| 花瓣阴影 | `0 14px 30px -10px rgba(0,0,0,0.6)` |
| 播放键阴影 | `0 6px 16px -4px #6E8BFF` |
| Toast 阴影 | `0 12px 30px -8px rgba(0,0,0,0.5)` |

### 圆角
| Token | 值 |
|---|---|
| `radius`（大面板） | `16px` |
| Pill | `13px` |
| chip/小按钮 | `7–9px` |
| tile/卡片内块 | `11px` |

### 缓动 / 动画
| Token | 值 |
|---|---|
| `ease`（标准） | `cubic-bezier(0.22, 0.61, 0.36, 1)` |
| `ease-back`（回弹） | `cubic-bezier(0.34, 1.56, 0.64, 1)` |
| 面板入场 `lb-in` | `0.24s ease`，`opacity 0→1` + `translateY(6px) scale(0.985) → none` |
| 旋转 `spin` | `0.7s linear infinite` |

### 字体
| Token | 字体栈 |
|---|---|
| 系统 UI（默认） | `-apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Noto Sans SC", system-ui, sans-serif` |
| `read`（阅读/正文） | `-apple-system, "PingFang SC", "Noto Sans SC", sans-serif` |
| `mono`（等宽/英文短语） | `"Space Grotesk", -apple-system, sans-serif` |
| 行高 | 中文 `1.78`，英文 `1.55` |

### 全局玻璃模糊
- 大部分玻璃面：`backdrop-filter: blur(28px) saturate(150%)`
- 命令面板：`blur(30px) saturate(160%)`
- 径向中心：`blur(24px) saturate(150%)`；花瓣 `blur(20px) saturate(140%)`

---

## 2. 公共元素

### 圆形图标按钮 `.iconbtn`
- 尺寸 `26×26`，圆角 `7`，无边框，背景透明
- 颜色 `text-3`(38% 白)
- **hover**：背景 `chip-hover`，颜色 `text`(95% 白)
- 过渡 `background .14s, color .14s`

### 底部按钮 `.foot-btn`
- 高 `30`，内边距 `0 11`，圆角 `8`，gap `5`
- 背景 `chip`，文字 `text-2`，字号 `12.5`，字重 500
- **hover**：背景 `chip-hover`，文字 `text`
- `.primary`：背景 `accent`，文字 `#fff`；**hover** `brightness(1.08)`

### Spinner（加载）
- `15×15`，圆，边框 `2px solid chip-hover`，顶边 `accent`，`spin 0.7s linear infinite`
- 加载行 `.loading-row`：gap `9`，padding `16 4`，文字 `text-3` 13px

### Toast
- 居中底部 `bottom: 96`，padding `7 14`，圆角 `9`，gap `7`
- 背景 **纯白 `#fff`**，文字 `#1A1A1F` 12.5px 字重 600
- 入场 `toast-in 0.2s ease`（`translateY 8→0` + 淡入）

---

## 3. 桌面舞台（演示外壳，非组件本体）

- `body` 背景 `#0D0E12`，抗锯齿开
- 壁纸：`radial-gradient(130% 130% at 14% 6%, #2D3A66 0%, #232A4A 34%, #1A1D33 64%, #111322 100%)`，叠加三处 screen 混合光晕
- 菜单栏：高 `26`，背景 `rgba(0,0,0,0.2)` + `blur(20px)`
- 阅读窗 `.docwin`：`top 70 / left 64`，宽 `600`，圆角 `14`，背景 `rgba(255,255,255,0.97)`（亮色），阴影 `0 30px 80px -20px rgba(0,0,0,0.6), 0 0 0 1px rgba(0,0,0,0.08)`
  - 标题栏高 `40`，红黄绿圆点各 `12×12`（`#FF5F57 / #FEBC2E / #28C840`）
  - 正文 `.docbody` padding `28 38 40`，衬线字体；正文 p `18px / 行高 1.74 / #2C2C34`
  - 选中目标 `.sel-target`：下划高亮 `linear-gradient(transparent 62%, rgba(110,139,255,0.32) 0)`；**hover** 抬到 `56% / 0.45`；激活态实底 `rgba(110,139,255,0.28)`

---

## 4. 模型四：工具面板（PANEL）— 主推方案

整体 `.panelmodel`：宽 **720**，纵向 flex，子项间距 `gap 8`（pill 与面板之间 8px），入场 `lb-in`。

### 4.1 顶部 Pill `.pm-pill`
| 属性 | 值 |
|---|---|
| 布局 | flex 横向，居中对齐，gap `10` |
| 内边距 | `7 8 7 15`（上右下左） |
| 圆角 | `13` |
| 背景 | `glass` + `blur(28px) saturate(150%)` |
| 描边 | `1px solid hairline` |
| 阴影 | `shadow` |
| 高度 | 约 `44`（由内容撑开） |

- 选区摘要 `.pm-src`：占满剩余宽（flex 1），基线对齐，gap `9`
  - meta `.pm-src-meta`：11px，`text-3`，gap `6`；中间圆点 `3×3`
  - 正文 `.pm-src-text`：13px，`text-2`，单行省略号
- 工具簇 `.pm-tools`：内含拖动/Pin/关闭三个 `iconbtn`
  - 容器 padding `2`，圆角 `9`，背景 `chip`，按钮间 gap `1`
  - 簇内 iconbtn 尺寸压到 `24×24`
  - 激活态 `.on`（如 Pin 已固定）：颜色 `accent-text`，背景 `accent-weak`
  - 拖动手柄 `cursor: grab`，按下 `grabbing`

### 4.2 内容面板 `.pm-panel`
- 圆角 `16`（`radius`），背景 `glass` + `blur(28px) saturate(150%)`，描边 `1px hairline`，`overflow: hidden`，纵向 flex
- **Pin 固定时**：pill 和 panel 阴影都变 `0 0 0 1px accent, 0 24px 60px -18px rgba(0,0,0,0.7)`（强调色描边）

### 4.3 动作区 `.pm-actionbar`（三种形态，可切换）
公共：padding `12 16`，底部 `1px solid hairline` 分隔。

**形态 A — 文字网格 `.v-text`（默认推荐）**
- flex wrap，gap `7`
- 每个 chip `.a`：字号 13 / 字重 500，padding `7 14`，圆角 `9`，`1px solid hairline` 边框，透明背景，文字 `text-2`，gap `6`（图标+文字）
- **hover**：背景 `chip`，文字 `text`
- **激活 `data-active`**：背景 `accent-weak`，文字 `accent-text`，边框透明，字重 600
- 禁用 `data-disabled`：opacity `0.38`，不可点
- 过渡 `all .14s`

**形态 B — 图标方块 `.v-tile`**
- flex，gap `7`，每个 `.a` 等分（flex 1）
- 纵向：图标在上文字在下，gap `4`，padding `10 4 8`，圆角 `11`，背景 `chip`，无边框，11.5px
- **hover**：背景 `chip-hover`；**激活**：`accent-weak` + `accent-text`

**形态 C — 高频+更多 `.v-overflow`**
- flex 居中，gap `6`；前若干个 `.a`：padding `7 13`，圆角 `9`，背景 `chip`（无边框）
- **hover** `chip-hover`；**激活** `accent-weak`/`accent-text`/字重 600
- 「更多」按钮 `.more-btn`：`34×34`，圆角 `9`，背景 `chip`，靠右（`margin-left:auto`）
- 溢出菜单 `.pm-overflow-menu`：定位在按钮下方 `top 40 / right 0`，最小宽 `132`，padding `5`，圆角 `11`，玻璃背景 `blur(24px)`，描边 hairline
  - 菜单项 `.mi`：padding `8 10`，圆角 `8`，gap `9`，13px；**hover** `chip`；激活 `accent-text`

### 4.4 结果标题 + 正文
- 标题 `.pm-panel-title`：padding `13 18 4`，12px 字重 600 `text-2`，前置圆点 `6×6` 实色 `accent`，gap `8`
- 正文 `.pm-panel-body`：padding `6 18 14`，**最小高 176**，字号 15，可滚动，最大高 `56vh`
  - 内含译文 `.rb-gloss` 与改写主句 `.rw-primary` 字号放大到 `16.5`

### 4.5 横向控制条 `.pm-ctrlbar`（二次操作）
- flex 居中，gap `16`，padding `9 16`，顶部 `1px solid hairline`，背景 `rgba(255,255,255,0.022)`，可换行
- 分组 `.pm-ctrl-group`：gap `7`；标签 `.lbl` 11px `text-3`
- 选项 chip `.pm-ctrl-chip`：12px，padding `4 10`，圆角 `7`，`1px solid hairline` 边框，透明背景，`text-2`
  - **hover**：背景 `chip`，文字 `text`
  - **激活**：`accent-weak` + `accent-text`，边框透明，字重 600
- 弹性间隔 `.pm-ctrl-spacer`（flex 1，最小宽 12）把「更多」推到右端
- 「更多」主按钮 `.pm-ctrl-more`：高 `30`，padding `0 13`，圆角 `8`，背景 `accent`，文字 `#fff` 12.5px 字重 600，gap `6`；**hover** `brightness(1.08)`

### 4.6 底部 `.pm-leftfoot`
- flex，gap `4`，padding `8 14 12`，内含「复制 / 收藏」两个 `foot-btn`

---

## 5. 模型一：径向环形（RADIAL）

- 容器 `.radial` 绝对定位，`pointer-events: none`（仅子元素可点）
- 中心球 `.radial-center`：`56×56` 圆，玻璃 `blur(24px)`，居中变换 `translate(-50%,-50%)`，文字色 `accent-text`
  - 入场 `radial-pop 0.28s ease-back`：`scale(0.4)→1` + 淡入
- 花瓣 `.radial-petal`：`60×60` 圆，`glass-2` + `blur(20px)`，描边 hairline，纵向图标+文字 11px，阴影 `0 14px 30px -10px rgba(0,0,0,0.6)`
  - **hover**：背景实色 `accent`，文字 `#fff`，`scale(1.08)`
  - 入场 `petal-in 0.34s ease-back backwards`（从中心 `scale(0.3)` 飞出）
  - 禁用：opacity `0.35`
- 提示文字 `.radial-hint`：`top 92`，11px `text-3`
- 选完后结果卡 `.radial-card`：宽 `360`，最大高 `70vh`，圆角 16，玻璃 `blur(28px)`，`lb-in` 入场

---

## 6. 模型二：命令列表（COMMAND / Raycast 式）

- 容器 `.cmd`：宽 `460`，居中 `left 50% top 130`，圆角 16，玻璃 `blur(30px) saturate(160%)`，最大高 `560`，纵向 flex
- 搜索头 `.cmd-search`：padding `15 18`，底部 hairline 分隔，gap `11`
  - 标签 11px `text-3`；查询文本 14.5px `text`，单行省略
- 主体 `.cmd-body`：flex 横向
  - 左列表 `.cmd-list`：宽 `178`，padding `8`，右侧 hairline 分隔，可滚动
    - 组标签 `.cmd-group-label`：10px 字重 600，大写 letter-spacing `.07em`，`text-3`，padding `8 10 5`
    - 行 `.cmd-row`：padding `8 10`，圆角 `9`，gap `10`，13.5px `text-2`
      - **hover**：背景 `chip`
      - **激活 `data-active`**：背景实色 `accent`，文字 `#fff`
      - 快捷键 `.key`：10px 等宽，opacity `0.55`（激活时 `0.8`）
  - 右预览 `.cmd-preview`：flex 1，padding `14 16`，最大高 `460`，可滚动
    - 标题 12px 字重 600 + `6×6` accent 圆点
- 底栏 `.cmd-foot`：padding `9 16`，顶部 hairline，11px `text-3`，gap `12`
  - 操作项 `.act` **hover** 变 `text`

---

## 7. 模型三：内联注释层（INLINE）

- 工具条 `.inline-tab`：横向 chip 行，gap `3`，padding `4`，圆角 `12`，玻璃 `blur(24px)`，`lb-in 0.2s`
  - chip `.inline-chip`：`34×30`，圆角 `8`，透明底，`text-2`
    - **hover**：`chip-hover` + `text`；**激活**：实色 `accent` + `#fff`
- 注释卡 `.inline-note`：宽 `520`，圆角 `13`，玻璃 `blur(28px)`
  - 入场 `note-grow 0.28s ease`（`scaleY(0.92)→1` + `translateY(-6px)→0`，原点 top-left）
  - 顶部彩条 `.inline-note-rail`：高 `3`，`linear-gradient(90deg, accent, accent-2)`
  - 内边距 `.inline-note-inner`：`13 16 14`
  - 头部 `.tag`：11px 字重 600 `accent-text`；小标签 `.mini`：11px，padding `3 9`，圆角 `7`，hairline 边框；激活 `accent-weak`/`accent-text`
  - 底部 `.inline-note-foot`：顶部 hairline，gap `14`，11.5px `text-3`；操作 `.a` hover 变 `text`

---

## 8. 顶部模型切换器 + 底部辅助栏（演示控件，产品中可不实现）

### 切换器 `.mswitch`
- 居中 `top 40`，padding `5`，gap `4`，圆角 `15`，背景 `rgba(16,17,22,0.74)` + `blur(24px)`
- 选项 `.ms-opt`：纵向，padding `8 15`，圆角 `11`，最小宽 `124`，文字 60% 白
  - **hover**：背景 `rgba(255,255,255,0.07)`，文字 `#fff`
  - **激活**：背景 `rgba(255,255,255,0.13)`，文字 `#fff`
  - 名称 13px 字重 600；序号 10px 等宽 opacity 0.55；描述 10.5px opacity 0.62

### 底部辅助 `.helper`
- 居中 `bottom 22`，gap `14`，11.5px，50% 白
- 段按钮 `.seg`：11px，padding `3 9`，圆角 `7`，hairline 边框；激活 `data-on` 背景 `accent` 文字 `#fff`
- 形态按钮 `.vseg`：同上，激活背景用 `accent-2`
- 键帽 `.kbd`：10.5px 等宽，padding `2 7`，圆角 `6`，背景 `rgba(255,255,255,0.08)`，边框 `rgba(255,255,255,0.12)`

---

## 9. 还原要点速记

1. **一套深色玻璃**：所有浮层 = 半透明深色 `rgba(28,30,40,0.78)` + 背景模糊 28px + 1px 白色描边(9% 透明) + 大柔阴影。
2. **状态三段**：静态 `text-2`/`chip` → hover 加亮(`text`/`chip-hover`) → 激活用强调色弱底 `accent-weak` + `accent-text` 文字（命令行和内联例外，激活用实色 `accent` + 白字）。
3. **强调色**只有按钮主操作（复制 primary、更多、播放键、激活实色态）才用实色 `#6E8BFF`，其余都用弱底。
4. **圆角层级**：大面板 16 → pill 13 → 卡内块 11 → chip/按钮 7–9。
5. **过渡统一** `.14s`，入场动画 `cubic-bezier(0.22,0.61,0.36,1)`，回弹元素（径向）用 `cubic-bezier(0.34,1.56,0.64,1)`。
6. **面板宽度**：工具面板 720 / 命令 460 / 内联注释 520 / 径向卡 360。
