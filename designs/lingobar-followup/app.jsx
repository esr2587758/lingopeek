// app.jsx — orchestrator. Mode toggle (选中 / 输入) + side-by-side variant compare.

const { useState: aUseState, useRef: aUseRef, useCallback: aUseCallback } = React;

const MODES = [
  { id: "selection", name: "选中模式", ds: "读到不懂的句子 · 就着翻译结果追问" },
  { id: "input", name: "输入模式", ds: "写完一句改写 · 追着结果继续调" },
];

function App() {
  const [mode, setMode] = aUseState("selection");
  const [toast, setToast] = aUseState("");
  // remount variants on mode change so their internal chat resets cleanly
  const [gen, setGen] = aUseState(0);
  const toastT = aUseRef(null);

  const flash = aUseCallback((t) => {
    setToast(t);
    clearTimeout(toastT.current);
    toastT.current = setTimeout(() => setToast(""), 1500);
  }, []);

  const switchMode = (id) => { setMode(id); setGen((g) => g + 1); };

  return (
    <div className="stage">
      <div className="wallpaper" />
      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span><span className="mb-item">编辑</span>
        <span className="mb-item">视图</span><span className="mb-item">收藏</span>
        <div className="mb-right"><span>⌘.</span><span className="mono">周四 14:06</span><span>🔋 86%</span></div>
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

      <div className="fu-headline">
        <h1>追问 · 没懂的地方接着问</h1>
        <p>选中模式和输入模式共用同一套追问对话：纯文字、流式回答、锚定当前上下文。下面两栏对比两种呈现方式。</p>
      </div>

      {/* side-by-side compare */}
      <div className="fu-compare" key={gen}>
        <VariantInline mode={mode} flash={flash} />
        <VariantWindow mode={mode} flash={flash} />
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
