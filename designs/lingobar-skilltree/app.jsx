// app.jsx — 「语法星座」页面编排
const { useState, useRef } = React;

function App() {
  const [node, setNode] = useState(null);
  const [toast, setToast] = useState("");
  const toastT = useRef(null);
  const flash = (m) => { setToast(m); clearTimeout(toastT.current); toastT.current = setTimeout(() => setToast(""), 1800); };
  const onAct = ({ node, action }) => { flash("重新唤起浮层：" + node.label + " · " + action); setNode(null); };

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
        <div className="sk-body">
          <OverviewHeader />
          <Constellation onPick={setNode} picked={node} />
        </div>
      </div>

      <NodeDetail node={node} onClose={() => setNode(null)} onAct={onAct} />
      {toast && <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>}
    </div>
  );
}
ReactDOM.createRoot(document.getElementById("root")).render(<App />);
