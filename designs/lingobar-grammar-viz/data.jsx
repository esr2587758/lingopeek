// data.jsx — 语法解析数据模型（lingobar-grammar-viz）
// 难句样本（睡眠记忆主题）：覆盖前置/后置定语、同位语从句、被动语态、状语从句、固定搭配。
// 术语沿用 CONTEXT：主句/从句/修饰/逻辑关系 + 可复用句型。

// 成分角色 → 配色
const ROLES = {
  subject:   { zh: "主语", color: "#6e8bff", hl: "rgba(110,139,255,.22)" },
  predicate: { zh: "谓语", color: "#8a7dff", hl: "rgba(138,125,255,.22)" },
  object:    { zh: "宾语", color: "#4fb8c9", hl: "rgba(79,184,201,.22)" },
  attr:      { zh: "定语", color: "#e0915c", hl: "rgba(224,145,92,.22)" },
  adv:       { zh: "状语", color: "#5bbf8a", hl: "rgba(91,191,138,.22)" },
  appos:     { zh: "同位语", color: "#d6789f", hl: "rgba(214,120,159,.22)" },
  conj:      { zh: "连接词", color: "#b6bcc8", hl: "rgba(182,188,200,.20)" },
};

const SENTENCE = {
  en: "The findings published last year call into question long-held assumptions that memory is consolidated while we sleep.",
  zh: "去年发表的这些研究结果，使人们开始质疑「记忆是在我们睡眠时被巩固的」这一长期假设。",
};

// 成分块（含词级 tokens：pos 词性 / infl 屈折说明）
const CHUNKS = [
  { id: "s", role: "subject", text: "The findings", label: "主语",
    note: "复数主语，指上文的研究结果",
    tokens: [
      { w: "The", pos: "限定词", infl: "定冠词，特指" },
      { w: "findings", pos: "名词", infl: "复数 (-s)，find 的名词化" },
    ] },
  { id: "d1", role: "attr", text: "published last year", label: "后置定语",
    note: "过去分词短语作后置定语，被动含义（findings 被发表）",
    tokens: [
      { w: "published", pos: "过去分词", infl: "publish 的 -ed 分词，表被动" },
      { w: "last year", pos: "时间短语", infl: "作分词的时间状语" },
    ] },
  { id: "v", role: "predicate", text: "call into question", label: "谓语",
    note: "动词固定搭配；一般现在时表客观结论",
    tokens: [
      { w: "call", pos: "动词", infl: "原形，主语复数故不加 -s" },
      { w: "into question", pos: "介词短语", infl: "构成固定搭配的一部分" },
    ] },
  { id: "o", role: "object", text: "long-held assumptions", label: "宾语",
    note: "核心宾语；long-held 为前置定语（复合形容词）",
    tokens: [
      { w: "long-held", pos: "复合形容词", infl: "long + held(hold 的过去分词)，前置定语" },
      { w: "assumptions", pos: "名词", infl: "复数 (-s)" },
    ] },
  { id: "ap", role: "appos", text: "that memory is consolidated while we sleep", label: "同位语从句",
    note: "that 引导，说明 assumptions 的具体内容；内含被动 + 时间状语从句",
    tokens: [
      { w: "that", pos: "从属连词", infl: "引导同位语从句，不作成分" },
      { w: "memory", pos: "名词", infl: "从句主语，不可数" },
      { w: "is consolidated", pos: "动词(被动)", infl: "be + 过去分词，一般现在时被动" },
      { w: "while we sleep", pos: "状语从句", infl: "while 引导时间状语从句" },
    ] },
];

// 依存关系弧
const DEPS = [
  { from: "v", to: "s", label: "主谓", dir: "left" },
  { from: "s", to: "d1", label: "后置修饰", dir: "right" },
  { from: "v", to: "o", label: "动宾", dir: "right" },
  { from: "o", to: "ap", label: "同位", dir: "right" },
];

// 层次树
const TREE = {
  label: "主句 (independent clause)", role: "predicate",
  text: "The findings … call into question … assumptions",
  children: [
    { label: "主语", role: "subject", text: "The findings",
      children: [{ label: "后置定语（分词）", role: "attr", text: "published last year" }] },
    { label: "谓语（固定搭配）", role: "predicate", text: "call into question" },
    { label: "宾语", role: "object", text: "long-held assumptions",
      children: [
        { label: "同位语从句", role: "appos", text: "that memory is consolidated …",
          children: [
            { label: "从句主语", role: "subject", text: "memory" },
            { label: "从句谓语（被动）", role: "predicate", text: "is consolidated" },
            { label: "时间状语从句", role: "adv", text: "while we sleep",
              children: [
                { label: "从句主语", role: "subject", text: "we" },
                { label: "从句谓语", role: "predicate", text: "sleep" },
              ] },
          ] },
      ] },
  ],
};

// 主干提取
const TRUNK = {
  full: SENTENCE.en,
  core: [
    { w: "The findings", role: "subject" },
    { w: "call into question", role: "predicate" },
    { w: "assumptions", role: "object" },
  ],
  dropped: [
    "published last year（后置定语·分词）",
    "long-held（前置定语）",
    "that memory is consolidated while we sleep（同位语从句）",
  ],
  coreZh: "这些研究结果质疑了某些假设。",
};

// 时态 · 语态 · 语气（新增）
const TENSE = {
  clauses: [
    { scope: "主句", verb: "call into question", tense: "一般现在时", aspect: "一般体", voice: "主动",
      mood: "陈述", why: "用现在时表达普遍成立的客观结论，而非一次性事件。",
      svo: { agent: "The findings", action: "call into question", receiver: "assumptions" } },
    { scope: "同位语从句", verb: "is consolidated", tense: "一般现在时", aspect: "一般体", voice: "被动",
      mood: "陈述", why: "被动语态弱化施动者，强调“记忆被巩固”这一过程本身；现在时表客观规律。",
      svo: { agent: "(大脑/睡眠，被省略)", action: "consolidate", receiver: "memory" } },
    { scope: "时间状语从句", verb: "sleep", tense: "一般现在时", aspect: "一般体", voice: "主动",
      mood: "陈述", why: "while 从句用现在时表习惯性、伴随性动作。",
      svo: { agent: "we", action: "sleep", receiver: null } },
  ],
};

// 中英语序对照（新增）：英文按出现顺序编号，中文重排，标出后置修饰前移
const ORDER = {
  en: [
    { id: 1, text: "The findings", role: "subject", zhPos: 2 },
    { id: 2, text: "published last year", role: "attr", zhPos: 1, moved: true },
    { id: 3, text: "call into question", role: "predicate", zhPos: 5 },
    { id: 4, text: "long-held assumptions", role: "object", zhPos: 4 },
    { id: 5, text: "that memory is consolidated while we sleep", role: "appos", zhPos: 3, moved: true },
  ],
  // 中文重排后的顺序（引用上面的 id）
  zhOrder: [2, 1, 5, 4, 3],
  zhText: ["去年发表的", "这些研究结果", "（记忆在睡眠时被巩固）这一", "长期假设", "受到了质疑"],
  note: "英文的后置定语（②分词、⑤同位语从句）在中文里都要搬到被修饰名词的前面——这是中英语序最大的差异。",
};

const COLLOCATIONS = [
  { phrase: "call into question", pos: "v. phr.", zh: "对……提出质疑；动摇某种看法",
    note: "比 doubt 更书面，强调“动摇既有共识”。", example: "New data call into question the old model." },
  { phrase: "long-held assumption", pos: "n. phr.", zh: "长期持有的假设",
    note: "long-held 复合形容词常修饰 belief / assumption / view。", example: "a long-held belief about diet" },
  { phrase: "be consolidated", pos: "v. phr. (passive)", zh: "被巩固、被强化",
    note: "consolidate 在记忆/学习语境的高频被动搭配。", example: "Memories are consolidated during deep sleep." },
];

const PHRASES = [
  { en: "during / while …", zh: "在……期间" },
  { en: "published last year", zh: "去年发表的" },
  { en: "memory consolidation", zh: "记忆巩固（术语）" },
  { en: "cast doubt on", zh: "使人怀疑（近义）" },
  { en: "the assumption that …", zh: "……这一假设（同位语）" },
];

const GRAMMAR_POINTS = [
  { tag: "从句", title: "同位语从句 vs 定语从句", body: "that memory is consolidated… 解释 assumptions 的“内容”，是同位语从句；that 不作从句成分，不可省。定语从句的 that 则在从句中作主/宾语。", color: "#d6789f" },
  { tag: "语态", title: "被动表客观过程", body: "is consolidated 用被动，隐去施动者，把焦点放在 memory 上，符合科技英语客观、去人称的表达习惯。", color: "#4fb8c9" },
  { tag: "修饰", title: "前置 vs 后置定语", body: "long-held 在名词前（前置），published last year 与 that 从句在名词后（后置）。中文里后置修饰都要前移。", color: "#e0915c" },
  { tag: "非谓语", title: "过去分词作后置定语", body: "published last year = which were published last year 的简化，过去分词表被动、完成。", color: "#5bbf8a" },
];

const PATTERN = {
  en: "sth. calls into question the assumption that …",
  zh: "某事使人开始质疑「……」这一假设",
};

Object.assign(window, {
  ROLES, SENTENCE, CHUNKS, DEPS, TREE, TRUNK, TENSE, ORDER,
  COLLOCATIONS, PHRASES, GRAMMAR_POINTS, PATTERN,
});
