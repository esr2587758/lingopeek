// data.jsx — 「我的语言地图」数据模型
// 核心：每个语法/语言点都有「遇到次数 met」与「掌握度 mastery(0–1)」。
// 暴露 vs 掌握的差值 gap = 归一化(met) * (1 - mastery)：高频又没掌握 → gap 大 → 警示色亮起。

// 体系分类（涌现地图也用它给节点上色/分区）
const CATEGORIES = {
  tense:   { zh: "时态语态", color: "#8a7dff" },
  clause:  { zh: "从句", color: "#4fb8c9" },
  nonfin:  { zh: "非谓语", color: "#5bbf8a" },
  modify:  { zh: "修饰", color: "#e0915c" },
  colloc:  { zh: "固定搭配", color: "#6e8bff" },
  pattern: { zh: "句型逻辑", color: "#d6789f" },
};

// 节点：met=遇到次数，mastery=掌握度(0–1，由行为自动推断)，noLookupStreak=最近连续几次没查
// learned=主动学习/复习次数（仅展示努力，非掌握度本身）
const NODES = [
  // 高频盲区（met 高、mastery 低 → gap 大）
  { id: "passive",   label: "被动语态", cat: "tense",   met: 14, mastery: 0.18, learned: 1, streak: 0, since: 26, srcTop: "Nature" },
  { id: "appos",     label: "同位语从句", cat: "clause", met: 11, mastery: 0.22, learned: 0, streak: 0, since: 20, srcTop: "Nature" },
  { id: "subjunct",  label: "虚拟语气", cat: "tense",    met: 9,  mastery: 0.15, learned: 0, streak: 0, since: 18, srcTop: "The Atlantic" },
  { id: "postmod",   label: "后置定语", cat: "modify",   met: 13, mastery: 0.4,  learned: 2, streak: 1, since: 24, srcTop: "Nature" },
  // 巩固中（mastery 中等）
  { id: "relclause", label: "定语从句", cat: "clause",   met: 16, mastery: 0.55, learned: 4, streak: 2, since: 30, srcTop: "Medium" },
  { id: "participle",label: "分词作状语", cat: "nonfin", met: 8,  mastery: 0.5,  learned: 3, streak: 1, since: 16, srcTop: "Nature" },
  { id: "inversion", label: "倒装", cat: "pattern",      met: 6,  mastery: 0.48, learned: 2, streak: 1, since: 12, srcTop: "Kindle" },
  { id: "comparative",label: "比较结构", cat: "pattern", met: 7,  mastery: 0.6,  learned: 3, streak: 2, since: 14, srcTop: "Medium" },
  // 已掌握（mastery 高、streak 高 → gap 小，沉下去）
  { id: "calliq",    label: "call into question", cat: "colloc", met: 12, mastery: 0.9, learned: 5, streak: 4, since: 22, srcTop: "Nature" },
  { id: "perfect",   label: "现在完成时", cat: "tense",  met: 18, mastery: 0.92, learned: 6, streak: 5, since: 34, srcTop: "Slack" },
  { id: "objclause", label: "宾语从句", cat: "clause",   met: 15, mastery: 0.85, learned: 4, streak: 4, since: 28, srcTop: "Medium" },
  { id: "gerund",    label: "动名词", cat: "nonfin",     met: 10, mastery: 0.88, learned: 3, streak: 3, since: 20, srcTop: "邮件" },
  { id: "boildown",  label: "boil down to", cat: "colloc",met: 5, mastery: 0.8,  learned: 2, streak: 3, since: 10, srcTop: "Medium" },
  { id: "condit",    label: "条件状语从句", cat: "clause",met: 9, mastery: 0.78, learned: 3, streak: 3, since: 17, srcTop: "Slack" },
];

// 计算 gap（暴露 vs 掌握差值），归一化 met 到 0–1 再乘未掌握度
const MAX_MET = Math.max(...NODES.map((n) => n.met));
function gapOf(n) { return (n.met / MAX_MET) * (1 - n.mastery); }
// gap → 等级（用于色阶 / 分组）：blind 高频盲区 / firming 巩固中 / solid 已掌握
function levelOf(n) {
  if (n.mastery >= 0.75) return "solid";
  if (gapOf(n) >= 0.35) return "blind";
  return "firming";
}
// gap 警示色：从沉静（已掌握）到警示（高频盲区）
function gapColor(n) {
  const g = gapOf(n); // 0–~1
  if (levelOf(n) === "solid") return "#3a8d6f";        // 沉静绿
  if (levelOf(n) === "blind") return g > 0.5 ? "#ff6b5e" : "#ff9152"; // 红 / 橙警示
  return "#e0b052"; // 巩固中 暖黄
}

const LEVELS = {
  blind:   { zh: "高频盲区", desc: "常遇到却还没掌握", color: "#ff6b5e" },
  firming: { zh: "巩固中",   desc: "正在熟悉",         color: "#e0b052" },
  solid:   { zh: "已掌握",   desc: "再遇到也不用查",   color: "#3a8d6f" },
};

// 顶部一句话画像 + 朴素库存
const PORTRAIT = {
  line: "你已经在 14 个语法点、213 个词块上留下痕迹，其中 4 个正在变浅。",
  stats: [
    { k: "覆盖语法点", v: 14, suffix: "" },
    { k: "词块库存", v: 213, suffix: "" },
    { k: "本周新遇到", v: 9, suffix: "" },
    { k: "正在变浅", v: 4, suffix: "" },
  ],
  coverage: 0.38, // 常见语法点覆盖率
};

// 洞察条（系统自动生成的句子 + 行动入口）
const INSIGHTS = [
  { id: "i1", tone: "warn", text: "被动语态你遇到 14 次，还没收藏过任何相关句型。", action: "去学被动语态", target: "passive" },
  { id: "i2", tone: "good", text: "call into question 你三周前每次都查，最近 4 次都没查了——它变浅了。", action: "查看", target: "calliq" },
  { id: "i3", tone: "warn", text: "虚拟语气是你掌握度最低的高频点，建议优先看看。", action: "去学虚拟语气", target: "subjunct" },
];

// 成长轨迹（障碍变浅：曾经高 gap、如今 mastery 上升的点；按变浅时间排）
const TRAIL = [
  { id: "perfect",  label: "现在完成时", from: 0.3, to: 0.92, when: "5 周前 → 现在", note: "已彻底变浅" },
  { id: "calliq",   label: "call into question", from: 0.2, to: 0.9, when: "3 周前 → 现在", note: "最近 4 次都没查" },
  { id: "objclause",label: "宾语从句", from: 0.35, to: 0.85, when: "4 周前 → 现在", note: "稳定掌握" },
  { id: "relclause",label: "定语从句", from: 0.25, to: 0.55, when: "进行中", note: "还在巩固" },
];

Object.assign(window, {
  CATEGORIES, NODES, LEVELS, PORTRAIT, INSIGHTS, TRAIL,
  gapOf, levelOf, gapColor, MAX_MET,
});
