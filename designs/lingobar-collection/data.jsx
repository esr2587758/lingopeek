// data.jsx — Lingobar 收藏语料（50+ 条，5 种类型）
// 主题：Nature 睡眠/记忆长读 + 日常工作场景（Slack / 邮件 / 会议）
// 类型 per CONTEXT.md：短语 / 句型 / 例句 / 英文(改写) / 文本(原文)
// 公共字段：id, type, text, meta, src, when(排序键，越大越新)
// 类型特有字段：
//   短语   phrase 词 / ipa 音标 / meta 中文释义
//   句型   text 含占位符（用 {} 包裹会被高亮） / meta 用途
//   例句   text 整句 / colloc[] 需高亮的搭配词 / meta 标注
//   英文   text 改写结果 / origin 原始中文 / meta 风格
//   文本   text 摘录 / lang 'en'|'zh' / meta 备注

const LB_COLL_TYPES = ["短语", "句型", "例句", "英文", "文本"];

const LB_COLLECTION = [
  // ---------- 短语 (collocations / phrases) ----------
  { id: "p1",  type: "短语", text: "call into question", ipa: "/kɔːl ˈɪntə ˈkwestʃən/", meta: "对……提出质疑", src: "Nature", when: 240 },
  { id: "p2",  type: "短语", text: "lock in", ipa: "/lɒk ɪn/", meta: "锁定、固定下来", src: "Kindle", when: 150 },
  { id: "p3",  type: "短语", text: "tip the balance", ipa: "/tɪp ðə ˈbæləns/", meta: "打破平衡、起决定作用", src: "Nature", when: 232 },
  { id: "p4",  type: "短语", text: "at the expense of", ipa: "/ət ðə ɪkˈspens ɒv/", meta: "以……为代价", src: "The Atlantic", when: 120 },
  { id: "p5",  type: "短语", text: "circle back", ipa: "/ˈsɜːkl bæk/", meta: "稍后再议、回头跟进", src: "Slack", when: 90 },
  { id: "p6",  type: "短语", text: "weed out", ipa: "/wiːd aʊt/", meta: "剔除、筛除", src: "Nature", when: 210 },
  { id: "p7",  type: "短语", text: "on the fence", ipa: "/ɒn ðə fens/", meta: "犹豫不决、持观望态度", src: "邮件", when: 70 },
  { id: "p8",  type: "短语", text: "boil down to", ipa: "/bɔɪl daʊn tuː/", meta: "归结为、本质上是", src: "Medium", when: 188 },
  { id: "p9",  type: "短语", text: "hold up", ipa: "/həʊld ʌp/", meta: "站得住脚、经得起检验", src: "Nature", when: 176 },
  { id: "p10", type: "短语", text: "in light of", ipa: "/ɪn laɪt ɒv/", meta: "鉴于、考虑到", src: "The Atlantic", when: 64 },
  { id: "p11", type: "短语", text: "rule out", ipa: "/ruːl aʊt/", meta: "排除（可能性）", src: "Nature", when: 158 },
  { id: "p12", type: "短语", text: "take its toll", ipa: "/teɪk ɪts təʊl/", meta: "造成损耗、产生不良影响", src: "Kindle", when: 46 },

  // ---------- 句型 (reusable patterns) ----------
  { id: "s1", type: "句型", text: "{sth.} calls into question long-held assumptions about {how …}", meta: "用证据挑战既有认知", src: "Safari", when: 238 },
  { id: "s2", type: "句型", text: "It's not that {A}, it's that {B}", meta: "强调对比、纠正误解", src: "Medium", when: 130 },
  { id: "s3", type: "句型", text: "The more {X}, the more likely {Y}", meta: "正相关推断", src: "Nature", when: 204 },
  { id: "s4", type: "句型", text: "Rather than {doing A}, the authors {do B}", meta: "学术写作转折", src: "Nature", when: 196 },
  { id: "s5", type: "句型", text: "What {this finding} suggests is that {…}", meta: "引出结论", src: "The Atlantic", when: 112 },
  { id: "s6", type: "句型", text: "There's a growing body of evidence that {…}", meta: "引出研究共识", src: "Nature", when: 168 },
  { id: "s7", type: "句型", text: "Just because {A} doesn't mean {B}", meta: "反驳因果误推", src: "Medium", when: 58 },
  { id: "s8", type: "句型", text: "Could we {do X} before {we commit to Y}?", meta: "委婉提议先行验证", src: "Slack", when: 86 },
  { id: "s9", type: "句型", text: "On balance, {the data} points to {…}", meta: "综合权衡后下判断", src: "Nature", when: 142 },

  // ---------- 例句 (example sentences) ----------
  { id: "e1", type: "例句", text: "These numbers call into question the company's growth story.", colloc: ["call into question"], meta: "同结构例句", src: "例句", when: 230 },
  { id: "e2", type: "例句", text: "Sleep doesn't simply file memories away; it actively reshapes them.", colloc: ["file", "away", "reshapes"], meta: "同场景例句", src: "Nature", when: 226 },
  { id: "e3", type: "例句", text: "The effect held up even after the researchers controlled for age.", colloc: ["held up", "controlled for"], meta: "搭配例句", src: "例句", when: 180 },
  { id: "e4", type: "例句", text: "Stress takes its toll on the brain's ability to consolidate learning.", colloc: ["takes its toll", "consolidate"], meta: "同结构例句", src: "例句", when: 44 },
  { id: "e5", type: "例句", text: "In light of these results, the textbook account needs revising.", colloc: ["In light of", "needs revising"], meta: "同结构例句", src: "Nature", when: 62 },
  { id: "e6", type: "例句", text: "It boils down to whether the brain replays or rewrites the day.", colloc: ["boils down to", "replays", "rewrites"], meta: "搭配例句", src: "例句", when: 186 },
  { id: "e7", type: "例句", text: "Let's rule out the simplest explanation before we get creative.", colloc: ["rule out"], meta: "日常场景", src: "例句", when: 156 },
  { id: "e8", type: "例句", text: "A single bad night can tip the balance toward forgetting.", colloc: ["tip the balance"], meta: "同结构例句", src: "Nature", when: 231 },
  { id: "e9", type: "例句", text: "The team weeded out the noisy trials and reran the analysis.", colloc: ["weeded out"], meta: "搭配例句", src: "例句", when: 209 },

  // ---------- 英文 (rewrite results, with original) ----------
  { id: "r1", type: "英文", text: "Should we try it on a small scale first?", origin: "我们要不要先小范围试一下？", meta: "改写 · 更地道", src: "输入模式", when: 235 },
  { id: "r2", type: "英文", text: "Let's circle back on this next week.", origin: "这个我们下周再聊。", meta: "改写 · 更口语", src: "Slack", when: 92 },
  { id: "r3", type: "英文", text: "I'm a bit concerned this approach carries some risk.", origin: "我有点担心这个方案风险有点高。", meta: "改写 · 更正式", src: "输入模式", when: 118 },
  { id: "r4", type: "英文", text: "Happy to walk you through it whenever works for you.", origin: "你方便的时候我随时给你讲一遍。", meta: "改写 · 更地道", src: "邮件", when: 74 },
  { id: "r5", type: "英文", text: "Just flagging this so it doesn't slip through the cracks.", origin: "提一下这个，免得漏掉。", meta: "改写 · 更口语", src: "Slack", when: 60 },
  { id: "r6", type: "英文", text: "Could you share a bit more context on the timeline?", origin: "时间线方面能再多说一点背景吗？", meta: "改写 · 更正式", src: "邮件", when: 138 },
  { id: "r7", type: "英文", text: "That works for me — let's lock it in.", origin: "我觉得可以，那就这么定了。", meta: "改写 · 更口语", src: "Slack", when: 200 },
  { id: "r8", type: "英文", text: "I'll take another pass at it and send it over tonight.", origin: "我再改一版，今晚发给你。", meta: "改写 · 更地道", src: "邮件", when: 48 },

  // ---------- 文本 (original excerpts) ----------
  { id: "t1", type: "文本", text: "memory consolidates during sleep", lang: "en", meta: "原文摘录", src: "Nature", when: 224 },
  { id: "t2", type: "文本", text: "competing waves of activity that can both strengthen and weaken the same memory", lang: "en", meta: "原文摘录", src: "Nature", when: 220 },
  { id: "t3", type: "文本", text: "睡眠不是被动地归档，而是在主动地重写记忆。", lang: "zh", meta: "译文摘录", src: "Nature", when: 216 },
  { id: "t4", type: "文本", text: "The implication is unsettling for anyone who trusted a good night's rest.", lang: "en", meta: "原文摘录", src: "Nature", when: 172 },
  { id: "t5", type: "文本", text: "deep sleep replays the day's events, quietly filing them into long-term storage", lang: "en", meta: "原文摘录", src: "Nature", when: 164 },
  { id: "t6", type: "文本", text: "学习后的第一晚睡眠质量，可能决定了知识能否真正留存。", lang: "zh", meta: "笔记", src: "Kindle", when: 54 },
  { id: "t7", type: "文本", text: "the authors describe a tug-of-war between strengthening and forgetting", lang: "en", meta: "原文摘录", src: "The Atlantic", when: 104 },
  { id: "t8", type: "文本", text: "a single tidy process gives way to messy, overlapping rhythms", lang: "en", meta: "原文摘录", src: "Nature", when: 148 },
];

// 类型 → 强调色调（用于卡片左条 / 标签底色微调；统一在 accent 家族内）
const LB_TYPE_META = {
  短语: { en: "Phrase",  hint: "词组 / 搭配" },
  句型: { en: "Pattern", hint: "可复用句型" },
  例句: { en: "Example", hint: "例句" },
  英文: { en: "Rewrite", hint: "改写结果" },
  文本: { en: "Excerpt", hint: "原文摘录" },
};

Object.assign(window, { LB_COLLECTION, LB_COLL_TYPES, LB_TYPE_META });
