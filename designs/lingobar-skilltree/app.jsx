// app.jsx — 「语法星座」页面编排
const { useState, useRef } = React;

function App() {
  const [node, setNode] = useState(null);
  const [, setVer] = useState(0); // 确认「懂了」后强制重渲染，让星座重新上色
  const [toast, setToast] = useState("");
  const toastT = useRef(null);
  const flash = (m) => { setToast(m); clearTimeout(toastT.current); toastT.current = setTimeout(() => setToast(""), 1800); };
  const onAct = ({ node, action }) => { flash("重新唤起浮层：" + node.label + " · " + action); setNode(null); };

  // 「懂了」确认：切换某句的 confirms，或 nudge 一键标记已掌握
  const onConfirm = (n, key) => {
    const before = stateOf(n);
    if (key === "nudge") {
      // 补足确认到「已掌握」阈值（在隐藏计数里补差）
      n.hiddenConfirms = (n.hiddenConfirms || 0) + Math.max(0, MASTER_THRESHOLD - liveUnderstood(n));
    } else {
      n.confirms[key] = !n.confirms[key];
    }
    setVer((v) => v + 1);
    const after = stateOf(n);
    if (after === "mastered" && before !== "mastered") flash("✨ " + n.label + " 已掌握");
    else if (key !== "nudge") flash(n.confirms[key] ? "已标记：这句看懂了" : "已取消标记");
  };

  return (
    <div className="stage">
      <div className="wallpaper" />
      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span><span className="mb-item">编辑</span><span className="mb-item">窗口</span>
        <div className="mb-right"><span className="mono">周日 14:32</span><span>🔋 86%</span></div>
      </div>

      <div className="skwin">
        <div className="sk-titlebar">
          <div className="sk-title">
            <span className="sk-title-ic"><LBIcon name="tree" size={17} /></span>
            <div><div className="sk-title-name">语法星座</div><div className="sk-title-sub">从中心散开，点亮你的语法体系</div></div>
          </div>
          <StateLegend />
        </div>
        {/* 主体：星座（左）+ 详情栏（右），并排共存，互不遮挡 */}
        <div className="sk-body" data-panel={node ? "open" : undefined}>
          <div className="sk-main">
            <OverviewHeader />
            <Constellation onPick={setNode} picked={node} />
          </div>
          <NodeDetail node={node} onClose={() => setNode(null)} onAct={onAct} onConfirm={onConfirm} />
        </div>
      </div>

      {toast && <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>}
    </div>
  );
}
ReactDOM.createRoot(document.getElementById("root")).render(<App />);
