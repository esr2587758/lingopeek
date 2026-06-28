// app.jsx — 「我的语言地图」页面编排
const { useState, useRef } = React;

const FORMS = [
  { id: "galaxy", icon: "galaxy", name: "星系", desc: "节点自由聚合，盲区是大而亮的星" },
  { id: "system", icon: "grid",   name: "体系板块", desc: "按语法体系分区，含覆盖率" },
  { id: "wall",   icon: "cards",  name: "卡片墙", desc: "盲区 / 巩固 / 已掌握 三组" },
];

function App() {
  const [form, setForm] = useState("galaxy");
  const [node, setNode] = useState(null);
  const [toast, setToast] = useState("");
  const toastT = useRef(null);
  const flash = (m) => { setToast(m); clearTimeout(toastT.current); toastT.current = setTimeout(() => setToast(""), 1800); };

  const onAct = (it) => {
    const n = NODES.find((x) => x.id === it.target);
    flash("重新唤起浮层：" + (n ? n.label : it.target) + (it.action ? " · " + it.action : ""));
    setNode(null);
  };

  return (
    <div className="stage">
      <div className="wallpaper" />
      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span><span className="mb-item">编辑</span><span className="mb-item">窗口</span>
        <div className="mb-right"><span className="mono">周日 14:32</span><span>🔋 86%</span></div>
      </div>

      <div className="lmwin">
        {/* 标题 */}
        <div className="lm-titlebar">
          <div className="lm-title">
            <span className="lm-title-ic"><LBIcon name="layers" size={17} /></span>
            <div><div className="lm-title-name">我的语言地图</div><div className="lm-title-sub">你真实遇到的语言，照出盲区与成长</div></div>
          </div>
        </div>

        <div className="lm-scroll">
          <PortraitHeader />

          {/* 地图形态切换 */}
          <div className="lm-mapcard">
            <div className="lm-maphead">
              <div className="lm-formtabs">
                {FORMS.map((f) => (
                  <button key={f.id} className="lm-formtab" data-on={form === f.id} onClick={() => setForm(f.id)} title={f.desc}>
                    <LBIcon name={f.icon} size={15} /> {f.name}
                  </button>
                ))}
              </div>
              <div className="lm-coverage">
                <span className="lm-coverage-track"><i style={{ width: `${PORTRAIT.coverage * 100}%` }} /></span>
                常见语法点覆盖 {Math.round(PORTRAIT.coverage * 100)}%
              </div>
            </div>

            <GapLegend />

            <div className="lm-mapstage" data-form={form}>
              {form === "galaxy" && <GalaxyMap onPick={setNode} />}
              {form === "system" && <SystemMap onPick={setNode} />}
              {form === "wall" && <CardWall onPick={setNode} />}
            </div>
            <div className="lm-formhint">{FORMS.find((f) => f.id === form).desc}</div>
          </div>

          {/* 洞察 + 轨迹 两栏 */}
          <div className="lm-bottom">
            <InsightBar onAct={onAct} />
            <GrowthTrail />
          </div>
        </div>
      </div>

      <NodeDetail node={node} onClose={() => setNode(null)} onAct={onAct} />
      {toast && <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
