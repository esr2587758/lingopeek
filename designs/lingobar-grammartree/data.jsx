// data.jsx — 「语法星座」完整英语语法体系（放射状）
// 两大支柱：词法 Morphology / 句法 Syntax。根在中心，向四周散开。
// 每个已解锁节点带「遇到过的真实句子」eg[]（text/src/when 分钟前），点击从顶部往下列出。
// 状态：met===0 → locked；mastery>=0.75 → mastered；否则 unlocked。盲区=高暴露低掌握。

const CATS = {
  core:   { zh: "核心",  color: "#6e8bff" },
  morph:  { zh: "词法",  color: "#8a7dff" },
  verb:   { zh: "动词",  color: "#a07dff" },
  noun:   { zh: "名词类", color: "#4fb8c9" },
  syntax: { zh: "句法",  color: "#e0915c" },
  clause: { zh: "从句",  color: "#5bbf8a" },
  special:{ zh: "特殊句式", color: "#d6789f" },
};

// 例句生成助手（简洁）
const eg = (text, src, when) => ({ text, src, when });

const TREE = [
  { id: "root", label: "英语语法", parent: null, cat: "core", met: 99, mastery: 0.9, eg: [] },

  // ===== 两大支柱（纵向树里作为 L1 主干节点）=====
  { id: "morph",  label: "词法", parent: "root", cat: "morph",  met: 60, mastery: 0.7, eg: [] },
  { id: "syntax", label: "句法", parent: "root", cat: "syntax", met: 55, mastery: 0.6, eg: [] },

  // ===== 词法 → 词类 =====
  { id: "verb",  label: "动词", parent: "morph", cat: "verb", met: 40, mastery: 0.65, eg: [
    eg("The findings call into question old assumptions.", "Nature", 8),
    eg("Researchers have consolidated the data overnight.", "Nature", 40) ] },
  { id: "noun",  label: "名词", parent: "morph", cat: "noun", met: 20, mastery: 0.7, eg: [
    eg("The findings published last year were striking.", "Nature", 8) ] },
  { id: "article", label: "冠词", parent: "morph", cat: "noun", met: 14, mastery: 0.45, eg: [
    eg("The brain replays the day during sleep.", "Nature", 30),
    eg("A growing body of evidence supports this.", "Medium", 62) ] },
  { id: "pronoun", label: "代词", parent: "morph", cat: "noun", met: 12, mastery: 0.6, eg: [
    eg("It actively reshapes them as we sleep.", "Nature", 44) ] },
  { id: "adj",   label: "形容词", parent: "morph", cat: "noun", met: 16, mastery: 0.65, eg: [
    eg("long-held assumptions about memory", "Nature", 8) ] },
  { id: "adv",   label: "副词", parent: "morph", cat: "noun", met: 13, mastery: 0.55, eg: [
    eg("Sleep doesn't simply file memories away.", "Nature", 50) ] },
  { id: "prep",  label: "介词", parent: "morph", cat: "noun", met: 18, mastery: 0.4, eg: [
    eg("at the expense of accuracy", "The Atlantic", 120),
    eg("in light of these results", "Nature", 62) ] },
  { id: "conj",  label: "连词", parent: "morph", cat: "noun", met: 11, mastery: 0.6, eg: [
    eg("It's not that A, but rather that B.", "Medium", 70) ] },
  { id: "numeral", label: "数词", parent: "morph", cat: "noun", met: 0, mastery: 0, eg: [] }, // locked

  // ===== 动词系统（最大一支）=====
  { id: "tense", label: "时态", parent: "verb", cat: "verb", met: 30, mastery: 0.6, eg: [
    eg("The effect held up after controls.", "Nature", 180) ] },
  { id: "voice", label: "语态", parent: "verb", cat: "verb", met: 16, mastery: 0.3, eg: [] },
  { id: "mood",  label: "语气", parent: "verb", cat: "verb", met: 11, mastery: 0.5, eg: [] },
  { id: "modal", label: "情态动词", parent: "verb", cat: "verb", met: 9, mastery: 0.5, eg: [
    eg("Could we validate this before we commit?", "输入模式", 96) ] },
  { id: "nonfin", label: "非谓语", parent: "verb", cat: "verb", met: 20, mastery: 0.5, eg: [] },
  { id: "agree", label: "主谓一致", parent: "verb", cat: "verb", met: 8, mastery: 0.55, eg: [
    eg("A growing body of evidence supports it.", "Medium", 62) ] },

  // 时态四类
  { id: "t_simple", label: "一般时", parent: "tense", cat: "verb", met: 22, mastery: 0.9, eg: [
    eg("Stress takes its toll on the brain.", "例句", 44) ] },
  { id: "t_prog",   label: "进行时", parent: "tense", cat: "verb", met: 12, mastery: 0.75, eg: [
    eg("The field is rapidly changing.", "Medium", 130) ] },
  { id: "t_perf",   label: "完成时", parent: "tense", cat: "verb", met: 18, mastery: 0.55, eg: [
    eg("Researchers have controlled for age.", "Nature", 180) ] },
  { id: "t_perfprog", label: "完成进行时", parent: "tense", cat: "verb", met: 0, mastery: 0, eg: [] }, // locked

  // 语态
  { id: "v_active", label: "主动", parent: "voice", cat: "verb", met: 14, mastery: 0.85, eg: [
    eg("Sleep reshapes memories.", "Nature", 50) ] },
  { id: "v_passive", label: "被动", parent: "voice", cat: "verb", met: 14, mastery: 0.18, eg: [
    eg("Memory is consolidated while we sleep.", "Nature", 14),
    eg("The simplest explanation was ruled out.", "Nature", 156),
    eg("These claims have been called into question.", "Medium", 70) ] }, // 盲区

  // 语气
  { id: "m_indic", label: "陈述", parent: "mood", cat: "verb", met: 10, mastery: 0.8, eg: [
    eg("The data points the other way.", "输入模式", 52) ] },
  { id: "m_imper", label: "祈使", parent: "mood", cat: "verb", met: 0, mastery: 0, eg: [] }, // locked
  { id: "m_subj",  label: "虚拟语气", parent: "mood", cat: "verb", met: 9, mastery: 0.15, eg: [
    eg("If the data were cleaner, the result would hold.", "The Atlantic", 120),
    eg("I wish the sample had been larger.", "Medium", 200) ] }, // 盲区

  // 非谓语三类
  { id: "nf_inf",  label: "不定式", parent: "nonfin", cat: "verb", met: 10, mastery: 0.6, eg: [
    eg("They aimed to rule out confounders.", "Nature", 156) ] },
  { id: "nf_ger",  label: "动名词", parent: "nonfin", cat: "verb", met: 10, mastery: 0.88, eg: [
    eg("Consolidating memory takes time.", "邮件", 90) ] },
  { id: "nf_part", label: "分词", parent: "nonfin", cat: "verb", met: 13, mastery: 0.42, eg: [
    eg("The findings published last year...", "Nature", 8),
    eg("Controlled for age, the effect held.", "Nature", 180) ] },

  // 名词细分
  { id: "n_count", label: "可数性", parent: "noun", cat: "noun", met: 9, mastery: 0.65, eg: [] },
  { id: "n_plural", label: "单复数", parent: "noun", cat: "noun", met: 12, mastery: 0.7, eg: [
    eg("These numbers tell a different story.", "Medium", 60) ] },
  { id: "n_poss", label: "所有格", parent: "noun", cat: "noun", met: 7, mastery: 0.6, eg: [] },

  // 冠词细分
  { id: "art_a", label: "a/an", parent: "article", cat: "noun", met: 10, mastery: 0.5, eg: [] },
  { id: "art_the", label: "the", parent: "article", cat: "noun", met: 13, mastery: 0.45, eg: [
    eg("The brain replays the day.", "Nature", 30) ] },
  { id: "art_zero", label: "零冠词", parent: "article", cat: "noun", met: 6, mastery: 0.3, eg: [] },

  // 形容词比较
  { id: "adj_comp", label: "比较等级", parent: "adj", cat: "noun", met: 8, mastery: 0.6, eg: [
    eg("The more data, the more likely the effect.", "Nature", 204) ] },

  // ===== 句法 =====
  { id: "element", label: "句子成分", parent: "syntax", cat: "syntax", met: 24, mastery: 0.7, eg: [
    eg("The findings call into question assumptions.", "Nature", 8) ] },
  { id: "simple", label: "简单句", parent: "syntax", cat: "syntax", met: 18, mastery: 0.75, eg: [
    eg("Sleep reshapes memory.", "Nature", 50) ] },
  { id: "compound", label: "并列句", parent: "syntax", cat: "syntax", met: 12, mastery: 0.6, eg: [
    eg("It replays the day, and it rewrites it.", "Nature", 186) ] },
  { id: "complex", label: "复合句", parent: "syntax", cat: "clause", met: 28, mastery: 0.55, eg: [] },
  { id: "special", label: "特殊句式", parent: "syntax", cat: "special", met: 14, mastery: 0.45, eg: [] },

  // 五种基本句型
  { id: "sv_patterns", label: "五种基本句型", parent: "simple", cat: "syntax", met: 10, mastery: 0.7, eg: [
    eg("SVO: Sleep reshapes memory.", "例句", 50) ] },

  // 复合句 → 三大从句
  { id: "nounclause", label: "名词性从句", parent: "complex", cat: "clause", met: 16, mastery: 0.5, eg: [] },
  { id: "relclause",  label: "定语从句", parent: "complex", cat: "clause", met: 16, mastery: 0.55, eg: [
    eg("the assumptions that memory is fixed", "Nature", 8) ] },
  { id: "advclause",  label: "状语从句", parent: "complex", cat: "clause", met: 13, mastery: 0.7, eg: [
    eg("...while we sleep.", "Nature", 14) ] },

  // 名词性从句四类
  { id: "nc_subj", label: "主语从句", parent: "nounclause", cat: "clause", met: 6, mastery: 0.5, eg: [] },
  { id: "nc_obj",  label: "宾语从句", parent: "nounclause", cat: "clause", met: 15, mastery: 0.85, eg: [
    eg("They argue that sleep matters.", "Medium", 110) ] },
  { id: "nc_pred", label: "表语从句", parent: "nounclause", cat: "clause", met: 0, mastery: 0, eg: [] }, // locked
  { id: "nc_appos", label: "同位语从句", parent: "nounclause", cat: "clause", met: 11, mastery: 0.22, eg: [
    eg("the assumption that memory is consolidated in sleep", "Nature", 8),
    eg("the idea that the brain rewrites the day", "Nature", 186) ] }, // 盲区

  // 定语从句细分
  { id: "rc_pron", label: "关系代词", parent: "relclause", cat: "clause", met: 12, mastery: 0.6, eg: [
    eg("findings that call into question...", "Nature", 8) ] },
  { id: "rc_adv", label: "关系副词", parent: "relclause", cat: "clause", met: 7, mastery: 0.5, eg: [] },
  { id: "rc_restrict", label: "限制/非限制", parent: "relclause", cat: "clause", met: 8, mastery: 0.4, eg: [] },

  // 状语从句细分
  { id: "ac_time", label: "时间/地点", parent: "advclause", cat: "clause", met: 10, mastery: 0.75, eg: [
    eg("while we sleep", "Nature", 14) ] },
  { id: "ac_cond", label: "条件/让步", parent: "advclause", cat: "clause", met: 9, mastery: 0.5, eg: [
    eg("even after they controlled for age", "Nature", 180) ] },

  // 特殊句式
  { id: "sp_inv", label: "倒装", parent: "special", cat: "special", met: 6, mastery: 0.4, eg: [
    eg("Not only does it replay, it rewrites.", "Kindle", 220) ] },
  { id: "sp_emph", label: "强调句", parent: "special", cat: "special", met: 7, mastery: 0.5, eg: [
    eg("It is sleep that consolidates memory.", "Medium", 130) ] },
  { id: "sp_there", label: "There be", parent: "special", cat: "special", met: 8, mastery: 0.7, eg: [
    eg("There's growing evidence that...", "Nature", 168) ] },
  { id: "sp_ellip", label: "省略", parent: "special", cat: "special", met: 0, mastery: 0, eg: [] }, // locked
];

const MAX_MET = Math.max(...TREE.filter(n => n.id !== "root").map((n) => n.met));

// ===== 掌握 = 「懂了」确认累积 =====
// 掌握度不是手填的玄学分，而是你在阅读里点过几次「懂了」推出来的。
// 每次「懂了」抹掉剩余差距的 30%：0→0  1→.30  2→.51  3→.66  4→.76  5→.83 …
// 约 4 次确认（在不同句子/时间）→ 视为已掌握。可解释、会累积、防虚熟。
const MASTER_BASE = 0.7;
const MASTER_THRESHOLD = 4; // 达到「已掌握」所需的确认次数
function masteryFrom(u) { return u <= 0 ? 0 : 1 - Math.pow(MASTER_BASE, u); }
function understoodFrom(mastery) { // 把作者预设的 mastery 反推成「懂了」次数作为种子
  if (mastery <= 0) return 0;
  return Math.round(Math.log(1 - Math.min(mastery, 0.985)) / Math.log(MASTER_BASE));
}
// 初始「懂了」次数种子（写回每个节点）
// confirms[]：每个例句你当时点没点「懂了」（最早遇到的先被确认）。
// hiddenConfirms：在未展示/更早句子里的确认次数。understood = hiddenConfirms + 已确认句子数。
TREE.forEach((n) => {
  // 掌握度 <0.3 视为「几乎没确认过」→ 种子 0（高频未确认 = 盲区）；其余按反推取整。
  const u = n.mastery < 0.3 ? 0 : understoodFrom(n.mastery);
  const len = (n.eg || []).length;
  const onSentences = Math.min(u, len);
  n.confirms = (n.eg || []).map((_, i) => i < onSentences); // 最早的若干句标记为已懂
  n.hiddenConfirms = Math.max(0, u - len);
  n.understood = n.hiddenConfirms + n.confirms.filter(Boolean).length;
});
function liveUnderstood(n) { return (n.hiddenConfirms || 0) + (n.confirms ? n.confirms.filter(Boolean).length : 0); }

function stateOf(n) {
  if (n.met === 0) return "locked";
  if (liveUnderstood(n) >= MASTER_THRESHOLD) return "mastered";
  return "unlocked";
}
// 高频盲区：遇到得多，却一次都没确认过「懂了」
function isBlind(n) { return stateOf(n) === "unlocked" && n.met >= 8 && liveUnderstood(n) === 0; }
// 轻推断兜底：遇到不少、却懒得标记 → 提示一键确认
function shouldNudge(n) { return stateOf(n) === "unlocked" && n.met >= 10 && liveUnderstood(n) >= 1 && liveUnderstood(n) < MASTER_THRESHOLD; }

const STATES = {
  locked:   { zh: "未探索", desc: "还没在阅读中遇到" },
  unlocked: { zh: "待掌握", desc: "遇到过，仍需确认" },
  mastered: { zh: "已掌握", desc: "你已多次确认看得懂" },
};

const OVERVIEW = {
  line: "你的语法星座已点亮 53 个节点，3 个高频盲区正在闪烁，5 个区域尚未探索。",
  stats: [ { k: "已解锁", v: 53 }, { k: "已掌握", v: 8 }, { k: "高频盲区", v: 3 }, { k: "未探索", v: 5 } ],
};

function relTime(min) {
  if (min < 60) return `${min} 分钟前`;
  const h = Math.floor(min / 60); if (h < 24) return `${h} 小时前`;
  return `${Math.floor(h / 24)} 天前`;
}

Object.assign(window, {
  CATS, TREE, MAX_MET, STATES, OVERVIEW,
  stateOf, isBlind, shouldNudge, relTime, liveUnderstood,
  masteryFrom, understoodFrom, MASTER_BASE, MASTER_THRESHOLD,
});
