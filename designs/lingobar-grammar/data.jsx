// data.jsx — structured grammar-parse model for "Structure Peek".
// Terminology follows CONTEXT.md: the action is 语法 (grammar view), not 拆解.
// The AI returns STRUCTURED data (per the PRD), not prose:
//   tokens · component spans + labels · relations · clause tree · phrase highlights.
// The renderers consume this shape directly and never parse free text.

/* ----------------------------------------------------------------------------
   COMPONENT TYPES — the colour language of the structure view.
   PRD locks: 主语 green · 谓语 blue · 状语 amber · 从句 light panel.
   宾语 / 定语 fill out a harmonious palette tuned to sit on warm cream.
   Each type carries a beginner gloss (易) and the formal term (zh/en).
---------------------------------------------------------------------------- */
const G_TYPES = {
  subject:   { zh: "主语", en: "Subject",    easy: "谁/什么",     solid: "#3f8f5f", text: "#2e7a4d", tint: "rgba(63,143,95,.14)",  line: "rgba(63,143,95,.6)" },
  predicate: { zh: "谓语", en: "Predicate",  easy: "做了什么",     solid: "#2f7fae", text: "#266c95", tint: "rgba(47,127,174,.15)", line: "rgba(47,127,174,.6)" },
  object:    { zh: "宾语", en: "Object",     easy: "对什么",       solid: "#9156a8", text: "#824a98", tint: "rgba(145,86,168,.14)", line: "rgba(145,86,168,.55)" },
  modifier:  { zh: "定语", en: "Modifier",   easy: "补充说明",     solid: "#2f9387", text: "#268176", tint: "rgba(47,147,135,.14)", line: "rgba(47,147,135,.55)" },
  adverbial: { zh: "状语", en: "Adverbial",  easy: "何时/怎样",    solid: "#c0823a", text: "#a96d28", tint: "rgba(192,130,58,.16)", line: "rgba(192,130,58,.6)" },
  clause:    { zh: "从句", en: "Clause",     easy: "一小句",       solid: "#8a7f70", text: "#6f6355", tint: "rgba(120,100,72,.10)", line: "rgba(120,100,72,.45)" },
};

/* ----------------------------------------------------------------------------
   THE SENTENCE — the selection being analysed (English → 语法 available).
---------------------------------------------------------------------------- */
const G_SENTENCE = {
  source: "The findings call into question long-held assumptions about how memory consolidates during sleep.",
  gloss: "这些发现使人们开始质疑“睡眠期间记忆如何巩固”这一长期假设。",
  app: "Safari",
  doc: "Nature · Neuroscience",
};

/* ----------------------------------------------------------------------------
   CHART BLOCKS — the left-to-right colour blocks of the structure chart.
   Two levels: 入门 collapses to the 4 backbone roles; 进阶 expands the
   modifier into a clause 画板 with its own subject / predicate / adverbial.
   Block ids are stable across levels so arcs + highlight linking line up.
---------------------------------------------------------------------------- */
const G_CHART = {
  easy: [
    { id: "s1", type: "subject",   text: "The findings" },
    { id: "p1", type: "predicate", text: "call into question", phrase: true },
    { id: "o1", type: "object",    text: "long-held assumptions" },
    { id: "m1", type: "modifier",  text: "about how memory consolidates during sleep" },
  ],
  adv: [
    { id: "s1", type: "subject",   text: "The findings" },
    { id: "p1", type: "predicate", text: "call into question", phrase: true },
    { id: "o1", type: "object",    text: "long-held assumptions" },
    { id: "about", type: "modifier", text: "about", lead: true },
    {
      id: "clause", type: "clause", panel: true, conj: "how", clauseKind: "宾语从句",
      children: [
        { id: "cs", type: "subject",   text: "memory" },
        { id: "cp", type: "predicate", text: "consolidates" },
        { id: "ca", type: "adverbial", text: "during sleep" },
      ],
    },
  ],
};

/* ----------------------------------------------------------------------------
   RELATIONS — arcs drawn beneath the chart (from → to, by block id).
   `kind` is the connector label; dashed = a modifying / non-core link.
---------------------------------------------------------------------------- */
const G_RELATIONS = {
  easy: [
    { from: "s1", to: "p1", kind: "主谓" },
    { from: "p1", to: "o1", kind: "动宾" },
    { from: "m1", to: "o1", kind: "修饰", dashed: true },
  ],
  adv: [
    { from: "s1", to: "p1", kind: "主谓" },
    { from: "p1", to: "o1", kind: "动宾" },
    { from: "about", to: "o1", kind: "修饰", dashed: true },
    { from: "cs", to: "cp", kind: "主谓" },
    { from: "ca", to: "cp", kind: "状语", dashed: true },
  ],
};

/* ----------------------------------------------------------------------------
   CLAUSE TREE — nesting backbone for the tree view (层次结构).
   `spans` are the block ids each node owns, for highlight linking.
---------------------------------------------------------------------------- */
const G_TREE = {
  role: "主句", roleEn: "Main clause", type: "predicate", spans: ["s1", "p1", "o1"],
  summary: "The findings · call into question · assumptions",
  summaryZh: "谁 + 做了什么 + 对什么",
  children: [
    {
      role: "后置定语", roleEn: "Postmodifier · 介词短语", type: "modifier", spans: ["m1", "about"],
      summary: "about how memory consolidates during sleep",
      summaryZh: "说明被质疑的是“哪一类”假设",
      children: [
        {
          role: "宾语从句", roleEn: "Object clause", type: "clause", spans: ["clause"],
          summary: "how memory consolidates during sleep",
          summaryZh: "作介词 about 的宾语",
          children: [
            { role: "主语", roleEn: "Subject",   type: "subject",   spans: ["cs"], summary: "memory" },
            { role: "谓语", roleEn: "Predicate", type: "predicate", spans: ["cp"], summary: "consolidates" },
            { role: "状语", roleEn: "Adverbial", type: "adverbial", spans: ["ca"], summary: "during sleep" },
          ],
        },
      ],
    },
  ],
};

/* ----------------------------------------------------------------------------
   PHRASE HIGHLIGHTS — fixed collocations worth collecting (短语 / 句型).
---------------------------------------------------------------------------- */
const G_PHRASES = [
  { text: "call into question", zh: "对……提出质疑", span: "p1", kind: "固定搭配" },
  { text: "long-held assumptions", zh: "长期以来的假设", span: "o1", kind: "常见搭配" },
];

/* ----------------------------------------------------------------------------
   INSIGHT CARDS — one key point each; `level` gates the advanced cards.
   `spans` lets a card light up its blocks + arcs in the chart on hover/click.
---------------------------------------------------------------------------- */
const G_CARDS = [
  { id: "k1", tag: "主句", tagEn: "Main clause", type: "predicate", level: "easy", spans: ["s1", "p1", "o1"],
    title: "先抓主干",
    body: "去掉所有修饰，核心是 The findings call into question assumptions——“这些发现质疑了某种假设”。" },
  { id: "k2", tag: "固定搭配", tagEn: "Fixed phrase", type: "predicate", level: "easy", spans: ["p1"],
    title: "call into question",
    body: "动词短语作谓语，比 doubt 更书面，强调“动摇已有共识”，可直接收藏复用。" },
  { id: "k3", tag: "后置定语", tagEn: "Postmodifier", type: "modifier", level: "adv", spans: ["m1", "about"],
    title: "about… 在修饰谁",
    body: "about 引导的介词短语后置，修饰前面的 assumptions，说明被质疑的是“关于记忆如何巩固”的那一类假设。" },
  { id: "k4", tag: "宾语从句", tagEn: "Object clause", type: "clause", level: "adv", spans: ["clause"],
    title: "how 引导的从句",
    body: "how memory consolidates during sleep 是一个完整的小句，整体作介词 about 的宾语——长句里最易读丢的一层。" },
];

/* ----------------------------------------------------------------------------
   REUSABLE PATTERN — the 可复用句型 (collected by default for 语法).
---------------------------------------------------------------------------- */
const G_PATTERN = {
  en: "sth. calls into question assumptions about how …",
  zh: "某事让人开始质疑关于……的看法",
};

Object.assign(window, {
  G_TYPES, G_SENTENCE, G_CHART, G_RELATIONS, G_TREE, G_PHRASES, G_CARDS, G_PATTERN,
});
