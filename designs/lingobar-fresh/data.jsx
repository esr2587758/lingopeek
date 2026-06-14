// data.jsx — mock content + scheme metadata for the Lingobar prototype.
// Terminology follows CONTEXT.md exactly: 翻译 / 语法 / 改写 / 例句 / 收藏 / 发音.

// ---- The four visual directions (all lightweight floating layers, Raycast/Spotlight-class) ----
const LB_SCHEMES = [
  {
    id: "glass",
    name: "Tahoe 玻璃",
    blurb: "贴合最新 macOS · 半透明玻璃材质 · 系统蓝",
    swatch: "#0a84ff",
  },
  {
    id: "tool",
    name: "克制工具",
    blurb: "Raycast / Linear 暗色 · 高对比 · 键盘优先",
    swatch: "#7c8cf8",
  },
  {
    id: "reader",
    name: "温暖阅读",
    blurb: "暖中性 + 衬线阅读字体 · 弱化聊天感",
    swatch: "#c0673c",
  },
  {
    id: "brand",
    name: "Lingobar 品牌",
    blurb: "自带珊瑚品牌色 · 独立图形语言",
    swatch: "#ff5a4d",
  },
];

// ---- Language actions, in the stable order from CONTEXT.md ----
// 翻译 / 语法 / 改写 / 例句 / 收藏 / 发音, with 复制 as a compact utility.
const LB_ACTIONS = [
  { id: "translate", label: "翻译", icon: "translate" },
  { id: "grammar", label: "语法", icon: "grammar" },
  { id: "rewrite", label: "改写", icon: "rewrite" },
  { id: "examples", label: "例句", icon: "examples" },
  { id: "collect", label: "收藏", icon: "star" },
  { id: "pronounce", label: "发音", icon: "sound" },
];

// ---- The selection the user is reading (English → defaults to 翻译) ----
const LB_SELECTION = {
  text: "The findings call into question long-held assumptions about how memory consolidates during sleep.",
  app: "Safari",
  doc: "Nature · Neuroscience",
};

// ---- Per-action result content ----
// Each action has a `rail`: the right-column control area in the wide panel.
// kind 'options' = groups of selectable chips; the left column is the output.
const LB_RESULTS = {
  translate: {
    title: "翻译",
    // contextual-more label per CONTEXT.md
    more: "解释更多",
    rail: {
      title: "翻译选项",
      groups: [
        { label: "语域", items: ["通用", "书面", "口语"], active: "通用" },
        { label: "呈现", items: ["精简", "详解"], active: "精简" },
      ],
    },
    body: {
      kind: "translate",
      gloss: "这些发现使人们对“睡眠期间记忆如何巩固”这一长期假设产生了质疑。",
      key: "call into question",
      keyZh: "对……提出质疑、动摇某种看法",
      note: "call into question 是固定搭配，比 doubt 更书面、更强调“动摇既有共识”。",
    },
  },
  grammar: {
    title: "语法",
    more: "继续拆解",
    rail: {
      title: "拆解粒度",
      groups: [
        { label: "层级", items: ["主干", "完整"], active: "完整" },
        { label: "标注", items: ["中文", "术语"], active: "中文" },
      ],
    },
    body: {
      kind: "grammar",
      blocks: [
        { role: "主句", text: "The findings call into question … assumptions", hint: "主谓宾主干" },
        { role: "固定搭配", text: "call into question", hint: "动词短语作谓语" },
        { role: "后置定语", text: "long-held assumptions about how …", hint: "about 引导介词短语修饰 assumptions" },
        { role: "宾语从句", text: "how memory consolidates during sleep", hint: "how 引导，作 about 的宾语" },
      ],
      pattern: "sth. calls into question assumptions about how …",
      patternZh: "某事让人开始质疑关于……的看法",
    },
  },
  rewrite: {
    title: "改写",
    more: "更多版本",
    rail: {
      title: "改写方向",
      groups: [
        { label: "语气", items: ["更口语", "更正式", "更简洁", "更地道"], active: "更地道" },
      ],
    },
    body: {
      kind: "rewrite",
      primary: "These results challenge what we've long assumed about how sleep helps the brain lock in memories.",
      variants: [
        { tone: "更口语", text: "Turns out what we thought about memory and sleep might be wrong." },
        { tone: "更正式", text: "The evidence undermines prevailing assumptions regarding sleep-dependent memory consolidation." },
        { tone: "更简洁", text: "This study makes us rethink how sleep stores our memories." },
      ],
    },
  },
  examples: {
    title: "例句",
    more: "更多例句",
    rail: {
      title: "例句类型",
      groups: [
        { label: "维度", items: ["搭配", "同结构", "同场景"], active: "同结构" },
        { label: "难度", items: ["基础", "进阶"], active: "基础" },
      ],
    },
    body: {
      kind: "examples",
      lead: "同结构句型 · 可直接套用",
      items: [
        "The report calls into question the safety of the new drug.",
        "Her testimony calls into question everything we believed about that night.",
        "These numbers call into question the company's growth story.",
      ],
    },
  },
  pronounce: {
    title: "发音",
    more: "慢速播放",
    rail: {
      title: "发音设置",
      groups: [
        { label: "口音", items: ["美音", "英音"], active: "美音" },
        { label: "语速", items: ["正常", "慢速"], active: "正常" },
      ],
    },
    body: {
      kind: "pronounce",
      word: "consolidate",
      ipa: "/kənˈsɒl.ɪ.deɪt/",
      stress: "重音在第二音节 -sol-",
      syllables: ["con", "sol", "i", "date"],
    },
  },
};

// ---- Input-mode draft + generated rewrite (no-selection workflow) ----
const LB_INPUT = {
  draft: "我觉得这个方案风险有点高，我们要不要先小范围试一下",
  directions: ["更口语", "更正式", "更简洁", "更地道"],
  result: {
    primary: "I think this plan is a bit risky — should we try it on a small scale first?",
    variants: [
      { tone: "更正式", text: "I'm concerned this approach carries some risk; perhaps we should pilot it on a limited scale first." },
      { tone: "更地道", text: "Honestly this feels a little risky — want to dip our toes in with a small test first?" },
    ],
  },
};

// ---- Collection window items ----
// type labels per CONTEXT.md: 文本 / 英文 / 例句 / 句型 / 短语
const LB_COLLECTION = [
  { type: "短语", text: "call into question", meta: "对……提出质疑", src: "Nature · 今天" },
  { type: "英文", text: "should we try it on a small scale first?", meta: "改写结果", src: "输入模式 · 今天" },
  { type: "句型", text: "sth. calls into question assumptions about how …", meta: "可复用句型", src: "Safari · 今天" },
  { type: "例句", text: "These numbers call into question the company's growth story.", meta: "同结构例句", src: "例句 · 昨天" },
  { type: "短语", text: "lock in", meta: "锁定、固定下来", src: "Kindle · 昨天" },
  { type: "文本", text: "memory consolidates during sleep", meta: "原文摘录", src: "Nature · 2 天前" },
  { type: "英文", text: "Let's circle back on this next week.", meta: "改写结果", src: "Slack · 3 天前" },
  { type: "句型", text: "It's not that …, it's that …", meta: "强调对比句型", src: "Medium · 上周" },
];

const LB_COLLECTION_FILTERS = ["全部", "短语", "英文", "句型", "例句", "文本"];

Object.assign(window, {
  LB_SCHEMES, LB_ACTIONS, LB_SELECTION, LB_RESULTS,
  LB_INPUT, LB_COLLECTION, LB_COLLECTION_FILTERS,
});
