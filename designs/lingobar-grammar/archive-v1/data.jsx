// data.jsx — 语法解析数据模型
// 样本长难句（睡眠记忆主题，与 fresh 一致）。术语沿用 CONTEXT：主句/从句/修饰/逻辑关系 + 可复用句型。

// 成分角色 → 配色（深色玻璃内的一组可区分色相）
const ROLES = {
  subject:   { zh: "主语", color: "#6e8bff", hl: "rgba(110,139,255,.22)" },
  predicate: { zh: "谓语", color: "#8a7dff", hl: "rgba(138,125,255,.22)" },
  object:    { zh: "宾语", color: "#4fb8c9", hl: "rgba(79,184,201,.22)" },
  attr:      { zh: "定语", color: "#e0915c", hl: "rgba(224,145,92,.22)" },
  adv:       { zh: "状语", color: "#5bbf8a", hl: "rgba(91,191,138,.22)" },
  conj:      { zh: "连接词", color: "#b6bcc8", hl: "rgba(182,188,200,.20)" },
};

// 整句（带词级标注）。每个 token：词、所属成分 role、可选 chunk(成分块id)
const SENTENCE = {
  en: "The findings call into question long-held assumptions about how memory consolidates during sleep.",
  zh: "这些发现使人们开始质疑关于「记忆如何在睡眠期间巩固」的长期假设。",
  tokens: [
    { w: "The findings", role: "subject", chunk: "s" },
    { w: "call into question", role: "predicate", chunk: "v" },
    { w: "long-held assumptions", role: "object", chunk: "o" },
    { w: "about how memory consolidates during sleep", role: "attr", chunk: "a" },
  ],
};

// 成分块（标注句下方色带 + 图例联动用）
const CHUNKS = [
  { id: "s", role: "subject",   text: "The findings",        label: "主语",  note: "复数主语，指代上文的研究结果" },
  { id: "v", role: "predicate", text: "call into question",  label: "谓语",  note: "动词固定搭配，作谓语；一般现在时表客观结论" },
  { id: "o", role: "object",    text: "long-held assumptions", label: "宾语", note: "core 宾语；long-held 为前置定语（复合形容词）" },
  { id: "a", role: "attr",      text: "about how memory consolidates during sleep", label: "后置定语", note: "about 介词短语修饰 assumptions，内含 how 引导的宾语从句" },
];

// 依存关系弧（词块之间的句法关系），用于 SVG 弧线图
const DEPS = [
  { from: "v", to: "s", label: "主谓", dir: "left" },
  { from: "v", to: "o", label: "动宾", dir: "right" },
  { from: "o", to: "a", label: "后置修饰", dir: "right" },
];

// 层次树（主干 → 从句 → 修饰，逐层嵌套）
const TREE = {
  label: "主句 (independent clause)", role: "predicate",
  text: "The findings call into question … assumptions",
  children: [
    { label: "主语", role: "subject", text: "The findings" },
    { label: "谓语（固定搭配）", role: "predicate", text: "call into question" },
    { label: "宾语", role: "object", text: "long-held assumptions",
      children: [
        { label: "后置定语（介词短语）", role: "attr", text: "about …",
          children: [
            { label: "宾语从句", role: "object", text: "how memory consolidates during sleep",
              children: [
                { label: "从句主语", role: "subject", text: "memory" },
                { label: "从句谓语", role: "predicate", text: "consolidates" },
                { label: "时间状语", role: "adv", text: "during sleep" },
              ] },
          ] },
      ] },
  ],
};

// 主干提取（剥掉修饰，只留骨架）
const TRUNK = {
  full: "The findings call into question long-held assumptions about how memory consolidates during sleep.",
  core: [
    { w: "The findings", role: "subject" },
    { w: "call into question", role: "predicate" },
    { w: "assumptions", role: "object" },
  ],
  dropped: ["long-held（前置定语）", "about how memory consolidates during sleep（后置定语 + 从句）"],
  coreZh: "这些发现质疑了某些假设。",
};

// 固定搭配
const COLLOCATIONS = [
  { phrase: "call into question", pos: "v. phr.", zh: "对……提出质疑；动摇某种看法",
    note: "比 doubt 更书面，强调“动摇既有共识”。", example: "New data call into question the old model." },
  { phrase: "long-held", pos: "adj.", zh: "长期持有的、由来已久的",
    note: "复合形容词作前置定语，常修饰 belief / assumption / view。", example: "a long-held belief about diet" },
];

// 常见词组（轻量 chips）
const PHRASES = [
  { en: "during sleep", zh: "在睡眠期间" },
  { en: "about how …", zh: "关于……如何……" },
  { en: "memory consolidation", zh: "记忆巩固（术语）" },
  { en: "raise questions about", zh: "对……提出疑问（近义）" },
  { en: "cast doubt on", zh: "使人怀疑（近义）" },
];

// 语法点（图文知识卡）
const GRAMMAR_POINTS = [
  { tag: "时态", title: "一般现在时表客观规律", body: "consolidates 用现在时，表达普遍成立的科学事实，而非一次性动作。", color: "#8a7dff" },
  { tag: "从句", title: "how 引导的宾语从句", body: "how memory consolidates during sleep 作介词 about 的宾语，整体充当名词。", color: "#4fb8c9" },
  { tag: "修饰", title: "前置 vs 后置定语", body: "long-held 在名词前（前置），about 介词短语在名词后（后置），共同修饰 assumptions。", color: "#e0915c" },
  { tag: "搭配", title: "抽象名词作宾语", body: "call into question 后常接 assumption / belief / claim 等抽象名词。", color: "#6e8bff" },
];

// 可复用句型
const PATTERN = {
  en: "sth. calls into question assumptions about how …",
  zh: "某事让人开始质疑关于……是如何……的看法",
};

Object.assign(window, {
  ROLES, SENTENCE, CHUNKS, DEPS, TREE, TRUNK, COLLOCATIONS, PHRASES, GRAMMAR_POINTS, PATTERN,
});
