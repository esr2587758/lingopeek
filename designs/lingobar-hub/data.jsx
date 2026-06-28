// data.jsx — Lingobar 主窗口（收藏 | 历史 | 设置）数据模型
// 收藏与历史同构：共用条目形状（type/text/meta/src/when…）。历史多 action + status。

// 三分区导航（分组）
const HUB_NAV = [
  { group: "我的内容", items: [
    { id: "collection", icon: "star",  name: "收藏",  desc: "主动留存的语言素材" },
    { id: "history",    icon: "clock", name: "历史",  desc: "查过的解析记录" },
  ] },
  { group: "应用", items: [
    { id: "settings", icon: "gear", name: "设置", desc: "AI · 权限 · 偏好" },
  ] },
];

const TYPE_HUES = {
  "短语": "#6e8bff", "句型": "#8a7dff", "例句": "#4fb8c9", "英文": "#5bbf8a", "文本": "#e0915c",
};
const COLL_TYPES = ["全部", "短语", "句型", "例句", "英文"];

// 收藏库
const COLLECTION = [
  { id: "p1", type: "短语", text: "call into question", ipa: "/kɔːl ˈɪntə ˈkwestʃən/", meta: "对……提出质疑", src: "Nature", when: 240 },
  { id: "p2", type: "短语", text: "lock in", ipa: "/lɒk ɪn/", meta: "锁定、固定下来", src: "Kindle", when: 150 },
  { id: "p3", type: "短语", text: "tip the balance", ipa: "/tɪp ðə ˈbæləns/", meta: "打破平衡、起决定作用", src: "Nature", when: 232 },
  { id: "p4", type: "短语", text: "at the expense of", ipa: "/ət ðə ɪkˈspens ɒv/", meta: "以……为代价", src: "The Atlantic", when: 120 },
  { id: "p5", type: "短语", text: "boil down to", ipa: "/bɔɪl daʊn tuː/", meta: "归结为、本质上是", src: "Medium", when: 188 },
  { id: "s1", type: "句型", text: "{sth.} calls into question assumptions about {how …}", meta: "用证据挑战既有认知", src: "Safari", when: 238 },
  { id: "s2", type: "句型", text: "It's not that {A}, it's that {B}", meta: "强调对比、纠正误解", src: "Medium", when: 130 },
  { id: "s3", type: "句型", text: "The more {X}, the more likely {Y}", meta: "正相关推断", src: "Nature", when: 204 },
  { id: "e1", type: "例句", text: "These numbers call into question the company's growth story.", colloc: ["call into question"], meta: "同结构例句", src: "例句", when: 230 },
  { id: "e2", type: "例句", text: "The effect held up even after the researchers controlled for age.", colloc: ["held up", "controlled for"], meta: "搭配例句", src: "Nature", when: 180 },
  { id: "en1", type: "英文", text: "Could we validate this on a small sample before we commit?", meta: "改写自“我们能不能先小范围验证下”", src: "输入模式", when: 96 },
  { id: "en2", type: "英文", text: "The data, on balance, points the other way.", meta: "改写自“数据总体上指向相反方向”", src: "输入模式", when: 52 },
];

// 历史记录（时间倒序；每条带 action 动作类型 + status 是否已收藏）
const HISTORY_ACTIONS = ["全部", "翻译", "语法", "改写", "例句"];
const HISTORY = [
  { id: "h1", action: "语法", type: "文本", text: "The findings published last year call into question long-held assumptions…", meta: "长难句结构解析", src: "Nature", when: 8, status: "saved" },
  { id: "h2", action: "翻译", type: "文本", text: "memory is consolidated while we sleep", meta: "记忆在我们睡眠时被巩固", src: "Nature", when: 14, status: "none" },
  { id: "h3", action: "改写", type: "英文", text: "Could we validate this on a small sample before we commit?", meta: "由中文改写为自然英文", src: "输入模式", when: 22, status: "saved" },
  { id: "h4", action: "例句", type: "例句", text: "Stress takes its toll on the brain's ability to consolidate learning.", meta: "take its toll 的同结构例句", src: "例句", when: 35, status: "none" },
  { id: "h5", action: "翻译", type: "短语", text: "at the expense of", meta: "以……为代价", src: "The Atlantic", when: 48, status: "saved" },
  { id: "h6", action: "语法", type: "文本", text: "It's not that the model is wrong, it's that the data was biased.", meta: "强调结构解析", src: "Medium", when: 70, status: "none" },
  { id: "h7", action: "改写", type: "英文", text: "The data, on balance, points the other way.", meta: "由口语改写为书面表达", src: "输入模式", when: 96, status: "saved" },
  { id: "h8", action: "翻译", type: "短语", text: "boil down to", meta: "归结为、本质上是", src: "Medium", when: 132, status: "none" },
  { id: "h9", action: "例句", type: "例句", text: "Let's rule out the simplest explanation before we get creative.", meta: "rule out 的日常场景例句", src: "例句", when: 168, status: "none" },
];

// 设置（移植自 lingobar-settings 完整内容）
const HUB_SETTINGS_NAV = [
  { id: "general", name: "通用" },
  { id: "ai", name: "AI 服务" },
  { id: "permissions", name: "权限" },
  { id: "trigger", name: "划词与唤起" },
  { id: "actions", name: "语言动作" },
  { id: "collectionPref", name: "收藏" },
  { id: "about", name: "关于" },
];
const AI_PROVIDERS = ["Claude (Anthropic)", "OpenAI", "自定义 / 兼容 OpenAI"];
const AI_MODELS = {
  "Claude (Anthropic)": ["claude-opus-4-8", "claude-sonnet-4-6", "claude-haiku-4-5"],
  "OpenAI": ["gpt-4o", "gpt-4o-mini"],
  "自定义 / 兼容 OpenAI": ["custom-model"],
};
const APPEARANCE_SCHEMES = [
  { id: "glass", name: "Tahoe 玻璃", desc: "系统浅玻璃 · 系统蓝", swatch: ["#f4f6f9", "#0a84ff"] },
  { id: "tool", name: "克制工具", desc: "深色 · 键盘优先", swatch: ["#1c1d24", "#8b9bff"] },
  { id: "reader", name: "温暖阅读", desc: "暖色 · 衬线阅读", swatch: ["#faf6ef", "#c0673c"] },
  { id: "brand", name: "品牌珊瑚", desc: "品牌色调", swatch: ["#1a1320", "#ff7a59"] },
];
const ACTION_ITEMS = [
  { id: "translate", label: "翻译", icon: "translate", note: "英文默认" },
  { id: "grammar", label: "语法", icon: "grammar", note: "仅英文" },
  { id: "rewrite", label: "改写", icon: "rewrite", note: "中文默认" },
  { id: "examples", label: "例句", icon: "examples" },
  { id: "collect", label: "收藏", icon: "star" },
  { id: "pronounce", label: "发音", icon: "sound" },
];
const COLLECT_MODES = [
  { id: "follow", label: "跟随当前面板", desc: "翻译收关键表达、改写收主句、例句收首条、语法收句型" },
  { id: "selection", label: "总是收原文", desc: "始终收藏选中的原始文本" },
];

// 相对时间（when = 多少“单位”前；这里用分钟近似演示）
function relTime(min) {
  if (min < 60) return `${min} 分钟前`;
  const h = Math.floor(min / 60);
  if (h < 24) return `${h} 小时前`;
  const d = Math.floor(h / 24);
  return `${d} 天前`;
}

Object.assign(window, {
  HUB_NAV, TYPE_HUES, COLL_TYPES, COLLECTION,
  HISTORY_ACTIONS, HISTORY, HUB_SETTINGS_NAV, AI_PROVIDERS, AI_MODELS,
  APPEARANCE_SCHEMES, ACTION_ITEMS, COLLECT_MODES, relTime,
});
