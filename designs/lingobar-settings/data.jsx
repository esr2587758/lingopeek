// data.jsx — Lingobar 设置：分区结构 + 默认值
// 配置项均来自 CONTEXT.md 的真实产品概念（setup gate / 动作优先级 / 默认动作 / 划词唤起 / 外观 等）。

const SETTINGS_SECTIONS = [
  { id: "general", icon: "gear", name: "通用", desc: "启动与外观" },
  { id: "ai", icon: "bolt", name: "AI 服务", desc: "模型接入", gate: true },
  { id: "permissions", icon: "shield", name: "权限", desc: "辅助功能", gate: true },
  { id: "trigger", icon: "cursor", name: "划词与唤起", desc: "如何呼出" },
  { id: "actions", icon: "sliders", name: "语言动作", desc: "顺序与默认" },
  { id: "collection", icon: "collection", name: "收藏", desc: "收藏行为" },
  { id: "about", icon: "info", name: "关于", desc: "版本信息" },
];

// 外观方案（对应 lingobar-fresh 的四套视觉）
const APPEARANCE_SCHEMES = [
  { id: "glass", name: "Tahoe 玻璃", desc: "系统浅玻璃 · 系统蓝", swatch: ["#f4f6f9", "#0a84ff"] },
  { id: "tool", name: "克制工具", desc: "深色 · 键盘优先", swatch: ["#1c1d24", "#8b9bff"] },
  { id: "reader", name: "温暖阅读", desc: "暖色 · 衬线阅读", swatch: ["#faf6ef", "#c0673c"] },
  { id: "brand", name: "品牌珊瑚", desc: "品牌色调", swatch: ["#1a1320", "#ff7a59"] },
];

// 语言动作（默认顺序 per CONTEXT：翻译/语法/改写/例句/收藏/发音）
const ACTION_ITEMS = [
  { id: "translate", label: "翻译", icon: "translate", note: "英文默认" },
  { id: "grammar", label: "语法", icon: "grammar", note: "仅英文" },
  { id: "rewrite", label: "改写", icon: "rewrite", note: "中文默认" },
  { id: "examples", label: "例句", icon: "examples" },
  { id: "collect", label: "收藏", icon: "star" },
  { id: "pronounce", label: "发音", icon: "sound" },
];

const AI_PROVIDERS = ["Claude (Anthropic)", "OpenAI", "自定义 / 兼容 OpenAI"];
const AI_MODELS = {
  "Claude (Anthropic)": ["claude-opus-4-8", "claude-sonnet-4-6", "claude-haiku-4-5"],
  "OpenAI": ["gpt-4o", "gpt-4o-mini"],
  "自定义 / 兼容 OpenAI": ["（在 Base URL 指定）"],
};

const COLLECT_TARGETS = [
  { id: "follow", label: "跟随当前面板", desc: "翻译收关键表达、改写收主句、例句收首条、语法收句型" },
  { id: "selection", label: "总是收原文", desc: "始终收藏选中的原始文本" },
];

Object.assign(window, {
  SETTINGS_SECTIONS, APPEARANCE_SCHEMES, ACTION_ITEMS, AI_PROVIDERS, AI_MODELS, COLLECT_TARGETS,
});
