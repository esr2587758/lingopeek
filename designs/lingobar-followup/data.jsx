// data.jsx — content for the 追问 (follow-up conversation) exploration.
// Terminology follows CONTEXT.md: input mode serves 改写 / natural English expression;
// the follow-up thread is anchored to the current selection or result — a focused
// follow-up, NOT an open-ended Ask AI. Copy stays scoped to reading + expression.

// ---- Selection-mode context: what Lingobar is showing before 追问 ----
// This is the 语法 (grammar) result — deliberately tall, so the right-side
// chat dock's independent scroll is the point: a long result on the left,
// its own scrolling conversation on the right, neither fighting the other.
const FU_SELECTION = {
  app: "Safari",
  doc: "Nature · Neuroscience",
  text: "The findings call into question long-held assumptions about how memory consolidates during sleep.",
  action: "语法",
  gloss: "这些发现使人们开始质疑“睡眠期间记忆如何巩固”这一长期假设。",
  key: "call into question",
  keyZh: "对……提出质疑、动摇某种看法",
  // structured grammar result blocks (from lingobar-grammar), rendered on the left column
  blocks: [
    { role: "主句", roleEn: "Main clause", text: "The findings call into question assumptions", hint: "去掉修饰后的核心：谁 + 做了什么 + 对什么。" },
    { role: "固定搭配", roleEn: "Fixed phrase", text: "call into question", hint: "动词短语作谓语，比 doubt 更书面，强调“动摇已有共识”。" },
    { role: "后置定语", roleEn: "Postmodifier", text: "about how memory consolidates during sleep", hint: "about 引导的介词短语后置，修饰前面的 assumptions。" },
    { role: "宾语从句", roleEn: "Object clause", text: "how memory consolidates during sleep", hint: "完整小句，整体作介词 about 的宾语——长句里最易读丢的一层。" },
  ],
  pattern: { en: "sth. calls into question assumptions about how …", zh: "某事让人开始质疑关于……的看法" },
  phrases: [
    { text: "call into question", zh: "对……提出质疑", kind: "固定搭配" },
    { text: "long-held assumptions", zh: "长期以来的假设", kind: "常见搭配" },
  ],
};

// ---- Input-mode context: the rewrite the user just generated ----
const FU_INPUT = {
  app: "输入模式",
  doc: "改写",
  draft: "我觉得这个方案风险有点高，我们要不要先小范围试一下",
  action: "改写",
  primary: "I think this plan is a bit risky — should we try it on a small scale first?",
};

// ---- Suggested follow-up prompts (chips), per mode ----
// Scoped to understanding + expression, never generic assistant tasks.
const FU_SUGGESTIONS = {
  selection: [
    "这句为什么用 call into question 而不是 doubt？",
    "consolidate 在这里怎么理解？",
    "帮我把这句改得更口语",
  ],
  input: [
    "能更委婉一点吗？",
    "risky 换个更地道的说法",
    "这样说在邮件里合适吗？",
  ],
};

// ---- Anchored context cards the user can attach / detach ----
const FU_CONTEXTS = {
  selection: { kind: "选区", label: "翻译 · call into question", text: FU_SELECTION.text },
  input: { kind: "改写结果", label: "改写 · 主结果", text: FU_INPUT.primary },
};

// ---- Scripted conversations. Each assistant turn streams token-by-token. ----
// `chunks` are appended with small delays to fake a real stream.
// Keep answers focused on reading comprehension / English expression.
const FU_THREADS = {
  selection: [
    {
      role: "user",
      text: "这句为什么用 call into question 而不是 doubt？",
    },
    {
      role: "assistant",
      chunks: [
        "两个词都表示“怀疑”，", "但语气和侧重点不同。\n\n",
        "**doubt** 更个人、更主观", "——“我个人不太相信”，", "程度较轻。\n\n",
        "**call into question** 是固定搭配，", "更书面、更强，", "强调“动摇了原本被广泛接受的共识”。",
        "原文说这些研究结果 call into question ", "*long-held assumptions*（长期假设），",
        "用它正好呼应“撼动既有定论”这层意思，", "比 doubt them 更有分量。",
      ],
      key: { term: "call into question", zh: "使…受到质疑（动摇共识）" },
    },
    {
      role: "user",
      text: "那我想在论文里表达“这削弱了原有结论”，还能怎么说？",
    },
    {
      role: "assistant",
      chunks: [
        "论文里可以用这几种，", "从强到弱：\n\n",
        "· **undermines** the previous conclusion", "（削弱、动摇根基，最正式）\n",
        "· **challenges** the earlier findings", "（提出挑战，中性偏学术）\n",
        "· **casts doubt on** the results", "（使…存疑，和 call into question 很接近）\n\n",
        "想收藏其中一个句型的话，", "点下方「收藏」就行。",
      ],
    },
  ],
  input: [
    {
      role: "user",
      text: "能更委婉一点吗？",
    },
    {
      role: "assistant",
      chunks: [
        "当然，", "把判断句改成建议句会更软：\n\n",
        "**I might be wrong, but this plan feels a little risky", " — could we maybe test it on a small scale first?**\n\n",
        "两个软化点：", "开头用 *I might be wrong, but* ", "先留余地；",
        "把 *should we* 换成 *could we maybe*，", "语气从“该不该”变成“方不方便”，", "在团队讨论里更不容易显得强硬。",
      ],
      rewrite: "I might be wrong, but this plan feels a little risky — could we maybe test it on a small scale first?",
    },
    {
      role: "user",
      text: "risky 有没有不那么负面的词？",
    },
    {
      role: "assistant",
      chunks: [
        "可以，", "换成中性一点的说法：\n\n",
        "· a bit **ambitious**（有点激进/进取，正面色彩）\n",
        "· **early-stage**（还比较早期）\n",
        "· needs a bit more **validation**（还需要多验证）\n\n",
        "比如：", "*this plan feels a little ambitious — ", "want to validate it on a small scale first?*",
      ],
      rewrite: "This plan feels a little ambitious — want to validate it on a small scale first?",
    },
  ],
};

Object.assign(window, {
  FU_SELECTION, FU_INPUT, FU_SUGGESTIONS, FU_CONTEXTS, FU_THREADS,
});
