// app.jsx — 编排：顶部形态切换 + state + 操作 handlers + 模拟工具面板
const { useState, useCallback, useRef } = React;

const FORMS = [
  { id: "compact", idx: "1", nm: "紧凑浮窗", ds: "贴右上角 · 时间流 + 筛选" },
  { id: "split",   idx: "2", nm: "中等双栏", ds: "左类型导航 + 右内容" },
  { id: "library", idx: "3", nm: "大库视图", ds: "近全屏 · 网格 + 详情抽屉" },
];

function App() {
  const [form, setForm] = useState("split");
  const [items, setItems] = useState(LB_COLLECTION);
  const [type, setType] = useState("全部");
  const [query, setQuery] = useState("");
  const [group, setGroup] = useState("type"); // 'type' | 'recent'
  const [detail, setDetail] = useState(null);
  const [toast, setToast] = useState("");
  const [relaunch, setRelaunch] = useState(null); // {item, action} → 模拟工具面板浮现
  const toastT = useRef(null);

  const flash = useCallback((msg) => {
    setToast(msg);
    clearTimeout(toastT.current);
    toastT.current = setTimeout(() => setToast(""), 1900);
  }, []);

  const onCopy = useCallback((item) => { flash("已复制：" + item.text.slice(0, 24) + (item.text.length > 24 ? "…" : "")); }, [flash]);

  const onDelete = useCallback((item) => {
    setItems((arr) => arr.filter((x) => x.id !== item.id));
    setDetail((d) => (d && d.id === item.id ? null : d));
    flash("已从收藏移除");
  }, [flash]);

  // 重新唤起 Lingobar：模拟工具面板带着该条内容浮现
  const onRelaunch = useCallback((item, action, fromRelated) => {
    if (fromRelated) { setDetail(item); return; }
    setRelaunch({ item, action: action || defaultActionFor(item) });
  }, []);

  const onOpen = useCallback((item) => {
    if (form === "library") setDetail(item); // 大库：右侧抽屉
    else onRelaunch(item);                    // 浮窗/双栏：直接唤起
  }, [form, onRelaunch]);

  const handlers = {
    onCopy, onDelete, onRelaunch, onOpen,
    onCloseWin: () => flash("（演示）收藏窗常驻，切换上方形态查看其它布局"),
    onCloseDetail: () => setDetail(null),
  };
  const state = { type, query, group };
  const set = { type: setType, query: setQuery, group: setGroup };

  return (
    <div className="stage">
      <div className="wallpaper" />

      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span>
        <span className="mb-item">编辑</span>
        <span className="mb-item">收藏</span>
        <div className="mb-right"><span className="mono">周日 14:32</span><span>🔋 86%</span></div>
      </div>

      {/* 顶部形态切换器 */}
      <div className="mswitch">
        {FORMS.map((f) => (
          <button key={f.id} className="ms-opt" data-active={form === f.id} onClick={() => { setForm(f.id); setDetail(null); }}>
            <span className="nm"><span className="idx">{f.idx}</span> {f.nm}</span>
            <span className="ds">{f.ds}</span>
          </button>
        ))}
      </div>

      {form === "compact" && <CompactForm items={items} state={state} set={set} handlers={handlers} />}
      {form === "split"   && <SplitForm   items={items} state={state} set={set} handlers={handlers} />}
      {form === "library" && <LibraryForm items={items} state={state} set={set} handlers={handlers} detail={detail} />}

      {relaunch && <RelaunchPanel data={relaunch} onClose={() => setRelaunch(null)} onToast={flash} />}

      {toast && <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>}

      <div className="helper">
        <span>切换上方 <b>形态</b> 体验三套收藏界面</span>
        <span>·</span>
        <span>点卡片或 <LBIcon name="spark" size={11} /> 重新唤起 Lingobar</span>
      </div>
    </div>
  );
}

function defaultActionFor(item) {
  switch (item.type) {
    case "短语": return "翻译";
    case "例句": return "例句";
    case "句型": return "语法";
    case "英文": return "改写";
    default: return "翻译";
  }
}

// 「重新唤起 Lingobar」→ 完整选区形态（PanelModel）：
// pill + 动作文字网格 + 结果标题 + 全宽正文 + 横向控制条 + 底部(复制/收藏)
// 内容用收藏项回填，切换动作即时改变正文。
const PANEL_ACTIONS = [
  { id: "翻译", icon: "translate" },
  { id: "语法", icon: "grammar" },
  { id: "改写", icon: "rewrite" },
  { id: "例句", icon: "examples" },
  { id: "发音", icon: "sound" },
];

function RelaunchPanel({ data, onClose, onToast }) {
  const { item } = data;
  const [action, setAction] = useState(data.action);
  const [rail, setRail] = useState({});
  const grammarDisabled = item.lang === "zh"; // 语法仅英文

  const pickAction = (a) => {
    if (a === "语法" && grammarDisabled) return;
    setAction(a);
  };
  const setRailVal = (k, v) => setRail((r) => ({ ...r, [k]: v }));

  return (
    <>
      <div className="relaunch-scrim" onClick={onClose} />
      <div className="lb">
        {/* PILL — 选中内容摘要 + 工具 */}
        <div className="lb-surface lb-pill">
          <div className="lb-src">
            <div className="lb-src-meta">
              <span>收藏</span>
              <span className="lb-src-dot" />
              <span>{item.type}</span>
            </div>
            <div className="lb-src-text" lang="en">{item.text}</div>
          </div>
          <div className="lb-tools">
            <button className="lb-iconbtn" title="收藏原文" onClick={() => onToast("已收藏原文")}><LBIcon name="star" size={15} /></button>
            <button className="lb-iconbtn" title="关闭 (Esc)" onClick={onClose}><LBIcon name="close" size={15} /></button>
          </div>
        </div>

        {/* PANEL */}
        <div className="lb-surface lb-panel">
          {/* 动作文字网格 */}
          <div className="lb-actionbar">
            {PANEL_ACTIONS.map((a) => {
              const disabled = a.id === "语法" && grammarDisabled;
              return (
                <button key={a.id} className="lb-act"
                  data-active={a.id === action}
                  data-disabled={disabled}
                  title={disabled ? "语法仅支持英文内容" : a.id}
                  onClick={() => !disabled && pickAction(a.id)}>
                  <LBIcon name={a.icon} size={15} /> {a.id}
                </button>
              );
            })}
          </div>

          {/* 结果标题 */}
          <div className="lb-panel-title"><span className="dot" /> {action} · 来自收藏</div>

          {/* 正文 — 按动作回填 */}
          <div className="lb-panel-body">
            <PanelContent item={item} action={action} onToast={onToast} />
          </div>

          {/* 横向控制条 */}
          <PanelControlBar action={action} rail={rail} onPick={setRailVal} onMore={() => onToast("生成更多内容…")} />

          {/* 底部 复制 / 收藏 */}
          <div className="lb-foot">
            <button className="lb-foot-btn" onClick={() => onToast("已复制")}><LBIcon name="copy" size={15} /> 复制</button>
            <button className="lb-foot-btn" onClick={() => onToast("已收藏")}><LBIcon name="star" size={15} /> 收藏</button>
          </div>
        </div>
      </div>
    </>
  );
}

// 各动作的正文（基于收藏项生成合理内容）
function PanelContent({ item, action, onToast }) {
  const t = item.text;
  if (action === "发音") {
    return (
      <div className="pr-wrap">
        <button className="pr-play" onClick={() => onToast("▶ 播放发音")}><LBIcon name="play" size={18} /></button>
        <div>
          <div className="pr-word" lang="en">{t}</div>
          {item.ipa ? <div className="pr-ipa">{item.ipa}</div> : <div className="pr-ipa">/ … /</div>}
        </div>
      </div>
    );
  }
  if (action === "语法") {
    return (
      <div>
        <div className="gr-block"><div className="gr-role">主干</div><div className="gr-text" lang="en">{firstClause(t)}</div></div>
        <div className="gr-block"><div className="gr-role">修饰</div><div className="gr-text" lang="en">{restClause(t)}</div></div>
        <div className="gr-pattern"><div className="lbl">可复用句型</div><div className="pt" lang="en">{item.type === "句型" ? renderPattern(t) : "sth. " + verbHint(t) + " …"}</div></div>
      </div>
    );
  }
  if (action === "改写") {
    return (
      <div>
        <div className="rw-primary" lang="en">{t}</div>
        <div style={{ marginTop: 8 }}>
          <div className="rw-var"><span className="rw-tone">更正式</span><span className="rw-var-text" lang="en">{t}</span></div>
          <div className="rw-var"><span className="rw-tone">更口语</span><span className="rw-var-text" lang="en">{t}</span></div>
        </div>
        {item.origin && <div className="tr-note">原文：{item.origin}</div>}
      </div>
    );
  }
  if (action === "例句") {
    const ex = LB_COLLECTION.filter((x) => x.type === "例句").slice(0, 3);
    return (
      <div>
        <div className="ex-lead">用「{shortText(t)}」的同结构例句：</div>
        {ex.map((e, i) => (
          <div className="ex-item" key={e.id}><span className="n">{i + 1}</span><span lang="en">{renderColloc(e.text, e.colloc)}</span></div>
        ))}
      </div>
    );
  }
  // 翻译（默认）
  return (
    <div>
      <div className="tr-gloss" lang="en">
        {item.type === "句型" ? renderPattern(t) : item.type === "例句" ? renderColloc(t, item.colloc) : t}
      </div>
      <div className="tr-key">
        <span className="k" lang="en">{shortText(t)}</span>
        <span className="kz">{item.meta || (LB_TYPE_META[item.type] || {}).hint}</span>
      </div>
    </div>
  );
}

// 横向控制条：每个动作的二次选项
const RAILS = {
  翻译: { label: "详略", chips: ["简洁", "详细"], def: "简洁", more: "深入解释" },
  语法: { label: "视角", chips: ["结构", "成分", "逻辑"], def: "结构", more: "完整拆解" },
  改写: { label: "方向", chips: ["更口语", "更正式", "更简洁", "更地道"], def: "更地道", more: "更多版本" },
  例句: { label: "场景", chips: ["通用", "学术", "日常"], def: "通用", more: "更多例句" },
  发音: { label: "语速", chips: ["正常", "慢速"], def: "正常", more: "跟读练习" },
};
function PanelControlBar({ action, rail, onPick, onMore }) {
  const cfg = RAILS[action];
  if (!cfg) return null;
  const key = action + ":sel";
  const active = rail[key] ?? cfg.def;
  return (
    <div className="lb-ctrlbar">
      <div className="lb-ctrl-group">
        <span className="lbl">{cfg.label}</span>
        <div className="lb-ctrl-chips">
          {cfg.chips.map((c) => (
            <button key={c} className="lb-ctrl-chip" data-active={c === active} onClick={() => onPick(key, c)}>{c}</button>
          ))}
        </div>
      </div>
      <div className="lb-ctrl-spacer" />
      <button className="lb-ctrl-more" onClick={onMore}><LBIcon name="spark" size={14} /> {cfg.more}</button>
    </div>
  );
}

// 极简文本工具（仅用于演示内容生成）
function firstClause(t) { const m = String(t).split(/[,;:]| that | which | because /); return m[0]; }
function restClause(t) { const m = String(t).split(/[,;:]| that | which | because /); return m.slice(1).join(" · ") || "—"; }
function verbHint(t) { const w = String(t).split(/\s+/); return w[1] || w[0] || "…"; }
function shortText(t) { const s = String(t); return s.length > 28 ? s.slice(0, 28) + "…" : s; }

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
