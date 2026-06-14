// app.jsx — interaction-models orchestrator. Owns state; switches between models.

const { useState: useS, useEffect: useE, useRef: useR, useCallback: useC } = React;

const MODELS = [
  { id: "radial", name: "径向环形", idx: "01", ds: "围绕选区成环 · 手势 · 极快" },
  { id: "command", name: "命令列表", idx: "02", ds: "Raycast 式 · 键盘 ↑↓⏎ 优先" },
  { id: "inline", name: "内联注释", idx: "03", ds: "附在选中句下 · 像文本多一层" },
  { id: "panel", name: "工具面板", idx: "04", ds: "工具条 + 下方面板 · 基线" },
];

const DEFAULT_ACTION = "translate";

function App() {
  const [model, setModel] = useS("radial");
  const [open, setOpen] = useS(true);
  const [action, setAction] = useS(DEFAULT_ACTION);
  const [loading, setLoading] = useS(false);
  const [toast, setToast] = useS("");
  // panel-model specifics
  const [pinned, setPinned] = useS(false);
  const [panelPos, setPanelPos] = useS({ top: 240, left: 360 });
  const [dragging, setDragging] = useS(false);
  const [selKind, setSelKind] = useS("long"); // 'long' | 'short' → demonstrates adaptive layout
  const [railSel, setRailSel] = useS({}); // right-rail option selections, keyed by action:group
  const [variant, setVariant] = useS("text"); // action-button form: 'text' | 'tile' | 'overflow'
  const dragRef = useR(null);
  const toastT = useR(null);
  const loadT = useR(null);

  const flash = useC((t) => {
    setToast(t);
    clearTimeout(toastT.current);
    toastT.current = setTimeout(() => setToast(""), 1500);
  }, []);

  const runLoad = useC(() => {
    setLoading(true);
    clearTimeout(loadT.current);
    loadT.current = setTimeout(() => setLoading(false), 460);
  }, []);

  const openLayer = useC(() => {
    setOpen(true);
    setAction(DEFAULT_ACTION);
    runLoad();
  }, [runLoad]);

  const doClose = useC(() => {
    clearTimeout(loadT.current);
    setLoading(false);
    setOpen(false);
  }, []);

  const pick = useC((id) => {
    if (id === "collect") { flash("已收藏到「收藏」"); return; }
    setAction(id);
    runLoad();
  }, [flash, runLoad]);

  // switching model re-opens fresh on the new model
  const switchModel = useC((id) => {
    setModel(id);
    setOpen(true);
    setAction(DEFAULT_ACTION);
    runLoad();
  }, [runLoad]);

  // keyboard: Esc closes; ⌘. toggles; in command model ↑↓ navigate + ⏎ (no-op, already live)
  useE(() => {
    const onKey = (e) => {
      if (e.key === "Escape") { if (open) doClose(); return; }
      if (e.key === "." && e.metaKey) { e.preventDefault(); open ? doClose() : openLayer(); return; }
      if (open && model === "command" && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
        e.preventDefault();
        const ids = LB_ACTIONS.map((a) => a.id);
        const cur = ids.indexOf(action);
        const next = e.key === "ArrowDown" ? (cur + 1) % ids.length : (cur - 1 + ids.length) % ids.length;
        pick(ids[next]);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, model, action, doClose, openLayer, pick]);

  // drag the panel via its handle / header
  const onDragStart = useC((e) => {
    e.preventDefault();
    const startX = e.clientX, startY = e.clientY;
    const base = { ...panelPos };
    setDragging(true);
    const onMove = (ev) => {
      const nx = Math.max(8, Math.min(window.innerWidth - 728, base.left + (ev.clientX - startX)));
      const ny = Math.max(32, Math.min(window.innerHeight - 120, base.top + (ev.clientY - startY)));
      setPanelPos({ top: ny, left: nx });
    };
    const onUp = () => {
      setDragging(false);
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
  }, [panelPos]);

  // two selections so the adaptive layout is demonstrable
  const SELECTIONS = {
    long: LB_SELECTION,
    short: { text: "consolidate", app: "Safari", doc: "Nature" },
  };

  // anchor geometry tied to the highlighted sentence in the doc window
  // sentence sits roughly at viewport (in docbody). We hard-anchor for the mock.
  const SEL = { x: 360, y: 300 };          // radial origin / inline tab anchor
  const common = {
    action, loading, onClose: doClose,
    onPick: pick,
    onCopy: () => flash("已复制"),
    onCollect: () => flash("已收藏到「收藏」"),
    onMore: () => flash("生成更多内容…"),
    onPlay: () => flash("▶ 播放发音"),
    flash,
  };

  return (
    <div className="stage">
      <div className="wallpaper" />
      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span><span className="mb-item">编辑</span>
        <span className="mb-item">视图</span><span className="mb-item">收藏</span>
        <div className="mb-right"><span>⌘.</span><span className="mono">周日 14:06</span><span>🔋 86%</span></div>
      </div>

      {/* model switcher */}
      <div className="mswitch">
        {MODELS.map((m) => (
          <button key={m.id} className="ms-opt" data-active={model === m.id} onClick={() => switchModel(m.id)}>
            <span className="nm"><span className="idx">{m.idx}</span>{m.name}</span>
            <span className="ds">{m.ds}</span>
          </button>
        ))}
      </div>

      <DocWindow onTrigger={openLayer} active={open} model={model} />

      {/* click-catcher behind the layer (always keeps content per guide) */}
      {open && (
        <div
          style={{ position: "absolute", inset: 0, zIndex: 20 }}
          onMouseDown={() => flash("有内容时点击外部不关闭")}
        />
      )}

      {open && model === "radial" && (
        <RadialModel origin={SEL} {...common} />
      )}
      {open && model === "command" && (
        <CommandModel {...common} />
      )}
      {open && model === "inline" && (
        <InlineModel anchor={{ x: 392, y: 360, noteX: 96, noteY: 392 }} {...common} />
      )}
      {open && model === "panel" && (
        <PanelModel
          pos={{ top: panelPos.top, left: panelPos.left }}
          selection={SELECTIONS[selKind]}
          {...common}
          pinned={pinned}
          onPin={() => { setPinned((p) => !p); flash(pinned ? "已取消固定" : "已固定"); }}
          onDragStart={onDragStart}
          dragging={dragging}
          railSel={railSel}
          onRailPick={(key, val) => { setRailSel((s) => ({ ...s, [key]: val })); runLoad(); }}
          variant={variant}
        />
      )}

      {!open && (
        <button
          onClick={openLayer}
          style={{
            position: "absolute", top: 300, left: 360, zIndex: 22,
            border: "none", borderRadius: 10, padding: "9px 14px", cursor: "pointer",
            background: "var(--accent)", color: "#fff", fontFamily: "inherit", fontSize: 13, fontWeight: 600,
            boxShadow: "var(--shadow)",
          }}
        >
          ⌘. 重新唤起 Lingobar
        </button>
      )}

      {toast && (
        <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>
      )}

      <div className="helper">
        <span>选中高亮句模拟唤起 · <b>{MODELS.find((m) => m.id === model).name}</b></span>
        <span><span className="kbd">⌘.</span> 唤起/关闭</span>
        <span><span className="kbd">esc</span> 关闭</span>
        {model === "command" && <span><span className="kbd">↑↓</span> 切换动作</span>}
        {model === "panel" && (
          <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
            动作形态：
            <button className="vseg" data-on={variant === "text"} onClick={() => setVariant("text")}>文字网格</button>
            <button className="vseg" data-on={variant === "tile"} onClick={() => setVariant("tile")}>图标方块</button>
            <button className="vseg" data-on={variant === "overflow"} onClick={() => setVariant("overflow")}>高频+更多</button>
            <span style={{ opacity: .6, marginLeft: 4 }}>· 选区</span>
            <button className="seg" data-on={selKind === "long"} onClick={() => { setSelKind("long"); if (open) runLoad(); }}>长句</button>
            <button className="seg" data-on={selKind === "short"} onClick={() => { setSelKind("short"); if (open) runLoad(); }}>单词</button>
          </span>
        )}
      </div>
    </div>
  );
}

function DocWindow({ onTrigger, active, model }) {
  return (
    <div className="docwin">
      <div className="docwin-bar">
        <span className="tl r" /><span className="tl y" /><span className="tl g" />
        <span className="docwin-title">Memory &amp; Sleep — Nature</span>
        <span className="docwin-url">nature.com</span>
      </div>
      <div className="docbody">
        <div className="kicker">Neuroscience</div>
        <h1>How sleep rewires what we remember</h1>
        <div className="byline">By E. Hartmann · 8 min read</div>
        <p>For decades, the textbook story was simple: the brain replays the day's events during deep sleep, quietly filing them into long-term storage.</p>
        <p>
          A new study complicates that picture.{" "}
          <span className={"sel-target" + (active ? " is-active" : "")} onClick={onTrigger} title="点击模拟「选中并按 ⌘.」">
            The findings call into question long-held assumptions about how memory consolidates during sleep.
          </span>{" "}
          Instead of a single tidy process, the authors describe competing waves of activity.
        </p>
        <p>The implication is unsettling for anyone who has trusted a good night's rest to lock in what they learned the day before.</p>
        {!active && (
          <p style={{ fontFamily: "var(--read)", fontSize: 13, color: "#5b66c2", background: "rgba(110,139,255,.1)", padding: "10px 12px", borderRadius: 10 }}>
            ↑ 点击高亮句子，看「{({ radial: "径向环形", command: "命令列表", inline: "内联注释", panel: "工具面板" })[model]}」如何唤起。
          </p>
        )}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
