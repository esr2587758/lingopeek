// app.jsx — the Lingobar 语法 (Structure Peek) floating panel + 3 layout variants.
// Each variant is an independent GrammarPanel instance (own view/level/labels/
// focus state), placed as a DCArtboard so they sit side-by-side for comparison.
const { useState, useRef, useCallback } = React;

/* =====================================================================
   GrammarPanel — one floating-layer instance.
   config: { layout: "stack"|"split"|"minimal", view, level, labels, width }
   ===================================================================== */
function GrammarPanel({ layout, view: view0, level: level0, labels: labels0 }) {
  const [view, setView] = useState(view0 || "chart");      // chart | tree
  const [level, setLevel] = useState(level0 || "easy");    // easy | adv
  const [labels, setLabels] = useState(labels0 ?? true);   // show component tags
  const [focus, setFocus] = useState(null);                // {ids?, type?} highlight
  const [toast, setToast] = useState("");
  const toastT = useRef(null);
  const flash = (m) => { setToast(m); clearTimeout(toastT.current); toastT.current = setTimeout(() => setToast(""), 1700); };

  // hover/click linking helpers
  const onFocusBlock = useCallback((b) => setFocus(b ? { ids: b.spans || [b.id], type: b.type } : null), []);
  const onFocusType = useCallback((t) => setFocus(t ? { type: t } : null), []);
  const onFocusCard = useCallback((c) => setFocus(c ? { ids: c.spans, type: c.type } : null), []);

  const split = layout === "split";
  const minimal = layout === "minimal";
  const legendTypes = level === "adv"
    ? ["subject", "predicate", "object", "modifier", "adverbial", "clause"]
    : ["subject", "predicate", "object", "modifier"];

  const viz = (
    <>
      {view === "chart" && !minimal && (
        <GLegend focus={focus} onFocusType={onFocusType} types={legendTypes} />
      )}
      <div className="g-vizbox">
        {view === "chart"
          ? <ChartView level={level} labels={labels} focus={focus}
              onFocusBlock={onFocusBlock} onFocusType={onFocusType} />
          : <TreeView focus={focus} onFocusBlock={onFocusBlock} />}
      </div>
    </>
  );

  const insights = <InsightCards level={level} focus={focus} onFocusCard={onFocusCard} />;

  return (
    <div className={"lb sel " + layout} data-scheme="reader">
      {/* ---- top pill: source + window tools ---- */}
      <div className="lb-surface lb-pill">
        <div className="lb-src">
          <div className="lb-src-meta"><span>{G_SENTENCE.app}</span><span className="lb-src-dot" /><span>{G_SENTENCE.doc}</span></div>
        </div>
        <div className="lb-tools">
          <button className="lb-iconbtn" title="拖动"><LBIcon name="drag" size={15} /></button>
          <button className="lb-iconbtn" title="固定"><LBIcon name="pin" size={15} /></button>
          <button className="lb-iconbtn" title="关闭 (Esc)"><LBIcon name="close" size={15} /></button>
        </div>
      </div>

      {/* ---- main panel ---- */}
      <div className="lb-surface lb-panel">
        {/* action bar (语法 active among the stable action order) */}
        {!minimal && (
          <div className="lb-actionbar">
            {[["翻译", false], ["语法", true], ["改写", false], ["例句", false], ["收藏", false], ["发音", false]].map(([l, on]) => (
              <button key={l} className="lb-act" data-active={on || undefined}>
                {on && <LBIcon name="grammar" size={14} />} {l}
              </button>
            ))}
          </div>
        )}

        {/* sentence + translation */}
        <div className="g-sentence">
          <div className="g-sentence-en" lang="en">{G_SENTENCE.source}</div>
          <div className="g-sentence-row">
            <button className="g-readbtn" title="朗读" onClick={() => flash("▶ 正在朗读原句")}><LBIcon name="sound" size={14} /></button>
            <div className="g-sentence-zh">{G_SENTENCE.gloss}</div>
          </div>
        </div>

        {/* title + recommended-parse disclaimer (PRD risk: 这是推荐解析) */}
        <div className="g-vizhead">
          <span className="g-vizhead-title"><span className="dot" />句子结构</span>
          <span className="g-reco" title="语法分析可能存在歧义，这是推荐解析"><LBIcon name="info" size={12} /> 推荐解析</span>
          <div style={{ flex: 1 }} />
          {/* view toggle: chart ↔ tree */}
          <div className="g-segment">
            <button className="g-seg" data-active={view === "chart"} onClick={() => setView("chart")} title="结构图"><LBIcon name="chart" size={14} /> 结构图</button>
            <button className="g-seg" data-active={view === "tree"} onClick={() => setView("tree")} title="层次结构"><LBIcon name="tree" size={14} /> 层次</button>
          </div>
        </div>

        {/* the visualisation (+ side rail in split layout) */}
        {split ? (
          <div className="g-splitbody">
            <div className="g-splitviz">{viz}</div>
            <div className="g-splitrail">{insights}<PhraseRow focus={focus} onFocusBlock={onFocusBlock} /></div>
          </div>
        ) : (
          <>
            {viz}
            {!minimal && <PhraseRow focus={focus} onFocusBlock={onFocusBlock} />}
            {insights}
          </>
        )}

        {/* reusable pattern */}
        {!minimal && (
          <div className="g-pattern">
            <span className="g-pattern-lbl">可复用句型</span>
            <div className="g-pattern-en" lang="en">{G_PATTERN.en}</div>
            <div className="g-pattern-zh">{G_PATTERN.zh}</div>
          </div>
        )}

        {/* control bar: level + label toggles */}
        <div className="lb-ctrlbar">
          <div className="lb-ctrl-group">
            <span className="lbl">解释级别</span>
            <div className="lb-ctrl-chips">
              <button className="lb-ctrl-chip" data-active={level === "easy"} onClick={() => setLevel("easy")}>入门</button>
              <button className="lb-ctrl-chip" data-active={level === "adv"} onClick={() => setLevel("adv")}>进阶</button>
            </div>
          </div>
          {view === "chart" && (
            <div className="lb-ctrl-group">
              <span className="lbl">成分标签</span>
              <button className="g-switch" data-on={labels} onClick={() => setLabels((v) => !v)} title="显示/隐藏成分标签">
                <LBIcon name="tag" size={13} /><span className="g-switch-track"><span className="g-switch-knob" /></span>
              </button>
            </div>
          )}
          <div className="lb-ctrl-spacer" />
          <button className="lb-ctrl-more" onClick={() => flash("继续拆解下一层…")}><LBIcon name="spark" size={13} /> 继续拆解</button>
        </div>

        {/* footer: copy / collect / export */}
        <div className="lb-foot">
          <button className="lb-foot-btn" onClick={() => flash("已复制文本解析")}><LBIcon name="copy" size={15} /> 复制解析</button>
          <button className="lb-foot-btn" onClick={() => flash("已收藏可复用句型")}><LBIcon name="star" size={15} /> 收藏句型</button>
          <div className="lb-foot-spacer" />
          <button className="lb-foot-btn primary" onClick={() => flash("已导出结构图 PNG")}><LBIcon name="export" size={15} /> 导出结构图</button>
        </div>
      </div>

      {toast && <div className="lb-toast"><LBIcon name="check" size={14} /> {toast}</div>}
    </div>
  );
}

/* =====================================================================
   The canvas: 3 layout directions side-by-side
   ===================================================================== */
function App() {
  return (
    <DesignCanvas>
      <DCSection id="grammar" title="Lingobar · 句子结构拆解" subtitle="温暖阅读配色 · 结构图 ↔ 层次树 · 入门/进阶 · 成分标签 · 点击联动高亮 · 复制/导出">
        <DCArtboard id="a" label="A · 经典浮窗（结构图优先）" width={468} height={836}>
          <ABackdrop><GrammarPanel layout="stack" view="chart" level="easy" labels={true} /></ABackdrop>
        </DCArtboard>
        <DCArtboard id="b" label="B · 宽幅双栏（图 + 洞察侧栏）" width={760} height={672}>
          <ABackdrop><GrammarPanel layout="split" view="chart" level="adv" labels={true} /></ABackdrop>
        </DCArtboard>
        <DCArtboard id="c" label="C · 极简入门（少术语 · 默认入门）" width={440} height={612}>
          <ABackdrop><GrammarPanel layout="minimal" view="chart" level="easy" labels={false} /></ABackdrop>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

/* warm desktop backdrop behind each floating panel so the glass reads true */
function ABackdrop({ children }) {
  return <div className="a-backdrop"><div className="a-wall" />{children}</div>;
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
