// app.jsx — orchestrator. Mode toggle (选中 / 输入) + variant toggle (右侧停靠 / 浮层窗).
// One full-size scene at a time, so the wide right-dock layout has real room.

const { useState: aUseState, useRef: aUseRef, useCallback: aUseCallback } = React;

const MODES = [
  { id: "selection", name: "选中模式", ds: "读到长难句 · 就着语法结果追问" },
  { id: "input", name: "输入模式", ds: "写完一句改写 · 追着结果继续调" },
];

const VARIANTS = [
  { id: "dock", name: "右侧停靠", ds: "对话作为右栏 · 结果与对话各自滚动" },
  { id: "window", name: "独立浮层窗", ds: "对话独立成窗 · 更专注" },
];

function App() {
  const [mode, setMode] = aUseState("selection");
  const [variant, setVariant] = aUseState("dock");
  const [toast, setToast] = aUseState("");
  const [gen, setGen] = aUseState(0); // remount scene to reset its chat cleanly
  const toastT = aUseRef(null);

  const flash = aUseCallback((t) => {
    setToast(t);
    clearTimeout(toastT.current);
    toastT.current = setTimeout(() => setToast(""), 1500);
  }, []);

  const bump = () => setGen((g) => g + 1);
  const switchMode = (id) => { setMode(id); bump(); };
  const switchVariant = (id) => { setVariant(id); bump(); };

  return (
    <div className="stage">
      <div className="wallpaper" />
      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span><span className="mb-item">编辑</span>
        <span className="mb-item">视图</span><span className="mb-item">收藏</span>
        <div className="mb-right"><span>⌘.</span><span className="mono">周五 14:06</span><span>🔋 86%</span></div>
      </div>

      {/* mode switcher */}
      <div className="mswitch">
        {MODES.map((m) => (
          <button key={m.id} className="ms-opt" data-active={mode === m.id} onClick={() => switchMode(m.id)}>
            <span className="nm">{m.name}</span>
            <span className="ds">{m.ds}</span>
          </button>
        ))}
      </div>

      {/* variant switcher (top-right) */}
      <div className="vswitch">
        <span className="vswitch-lbl">呈现</span>
        {VARIANTS.map((v) => (
          <button key={v.id} className="vs-opt" data-active={variant === v.id} onClick={() => switchVariant(v.id)} title={v.ds}>
            {v.name}
          </button>
        ))}
      </div>

      {/* single full-size scene */}
      <div className="fu-single" data-variant={variant} key={gen}>
        {variant === "dock"
          ? <VariantDock mode={mode} flash={flash} />
          : <VariantWindow mode={mode} flash={flash} />}
      </div>

      {toast && (
        <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>
      )}

      <div className="helper">
        <span>点 <b>追问</b> 唤起对话 · 回答逐字流式生成</span>
        <span><span className="kbd">⏎</span> 发送</span>
        <span>上下文卡片可点按 <b>锚定/取消</b></span>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
