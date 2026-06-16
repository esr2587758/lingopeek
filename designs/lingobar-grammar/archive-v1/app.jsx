// app.jsx — 语法解析界面编排
const { useState, useRef } = React;

const VIEWS = [
  { id: "annot", icon: "highlight", name: "成分标注", desc: "彩色高亮句子成分" },
  { id: "dep",   icon: "arc",       name: "依存关系", desc: "词块之间的句法弧" },
  { id: "tree",  icon: "tree",      name: "层次结构", desc: "主句→从句→修饰" },
  { id: "trunk", icon: "trunk",     name: "主干提取", desc: "剥离修饰看骨架" },
];

function App() {
  const [view, setView] = useState("annot");
  const [hover, setHover] = useState(null);
  const [toast, setToast] = useState("");
  const toastT = useRef(null);
  const flash = (m) => { setToast(m); clearTimeout(toastT.current); toastT.current = setTimeout(() => setToast(""), 1700); };

  return (
    <div className="stage">
      <div className="wallpaper" />
      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span><span className="mb-item">编辑</span>
        <div className="mb-right"><span className="mono">周日 14:32</span><span>🔋 86%</span></div>
      </div>

      <div className="gwin">
        {/* 顶部 pill：标题 + 样本句 */}
        <div className="g-pill">
          <div className="g-pill-left">
            <span className="g-pill-icon"><LBIcon name="grammar" size={16} /></span>
            <div className="g-pill-meta">
              <span className="g-title">语法解析</span>
              <span className="g-sub">长难句 · 成分 · 搭配 · 语法点</span>
            </div>
          </div>
          <button className="g-iconbtn" title="关闭" onClick={() => flash("（演示）")}><LBIcon name="close" size={16} /></button>
        </div>

        <div className="g-panel">
          {/* 样本句 + 译文 */}
          <div className="g-sentence">
            <div className="g-sentence-en" lang="en">{SENTENCE.en}</div>
            <div className="g-sentence-zh">{SENTENCE.zh}</div>
          </div>

          {/* 可视化视图切换 */}
          <div className="g-viewtabs">
            {VIEWS.map((v) => (
              <button key={v.id} className="g-viewtab" data-active={view === v.id} onClick={() => setView(v.id)} title={v.desc}>
                <LBIcon name={v.icon} size={15} /> {v.name}
              </button>
            ))}
          </div>

          {/* 可视化区 */}
          <div className="g-viz">
            {(view === "annot" || view === "dep") && <RoleLegend hover={hover} onHover={setHover} />}
            {view === "annot" && <AnnotatedView hover={hover} onHover={setHover} />}
            {view === "dep" && <DependencyView hover={hover} onHover={setHover} />}
            {view === "tree" && <TreeView />}
            {view === "trunk" && <TrunkView />}
          </div>

          {/* 可复用句型 */}
          <div className="g-pattern">
            <span className="g-pattern-lbl">可复用句型</span>
            <div className="g-pattern-en" lang="en">{PATTERN.en}</div>
            <div className="g-pattern-zh">{PATTERN.zh}</div>
          </div>

          {/* 知识模块：两列 */}
          <div className="g-knowledge">
            <div className="g-col">
              <div className="g-col-head"><LBIcon name="link2" size={15} /> 固定搭配</div>
              {COLLOCATIONS.map((c, i) => <CollocationCard key={i} c={c} onPlay={(w) => flash("▶ " + w)} />)}
              <div className="g-col-head g-col-head-sp"><LBIcon name="book" size={15} /> 常见词组</div>
              <div className="g-phrases">
                {PHRASES.map((p, i) => (
                  <span key={i} className="g-phrase" title={p.zh}><span lang="en">{p.en}</span><span className="g-phrase-zh">{p.zh}</span></span>
                ))}
              </div>
            </div>
            <div className="g-col">
              <div className="g-col-head"><LBIcon name="bulb" size={15} /> 语法点</div>
              {GRAMMAR_POINTS.map((p, i) => <GrammarPointCard key={i} p={p} />)}
            </div>
          </div>

          {/* 底部操作 */}
          <div className="g-foot">
            <button className="g-foot-btn" onClick={() => flash("已复制解析")}><LBIcon name="copy" size={15} /> 复制</button>
            <button className="g-foot-btn" onClick={() => flash("已收藏句型")}><LBIcon name="star" size={15} /> 收藏句型</button>
            <div className="g-foot-spacer" />
            <button className="g-foot-btn primary" onClick={() => flash("生成更多例句…")}><LBIcon name="spark" size={15} /> 举一反三</button>
          </div>
        </div>
      </div>

      {toast && <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
