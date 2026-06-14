// app.jsx — orchestrator. Owns all state; mounts the desktop scene + Lingobar layer.
// Implements the interaction rules from docs/interaction-guide.md:
//   空状态轻自动关，有内容重别乱关。Esc / 再按快捷键 / 关闭按钮 关闭。

const { useState, useEffect, useRef, useCallback } = React;

// English selection → default 翻译 ; the selection lives in the doc window.
const DEFAULT_ACTION = "translate";

function App() {
  const [scheme, setScheme] = useState("glass");
  const [mode, setMode] = useState("selection"); // 'selection' | 'input'
  const [open, setOpen] = useState(true);

  // selection mode
  const [action, setAction] = useState(DEFAULT_ACTION);
  const [loading, setLoading] = useState(false);
  const [pinned, setPinned] = useState(false);
  const [railSel, setRailSel] = useState({}); // secondary-control selections, keyed by action:group
  const [panelPos, setPanelPos] = useState({ top: 240, left: 360 });
  const [dragging, setDragging] = useState(false);
  // selected text + the pop button that surfaces on a live text selection
  const [selection, setSelection] = useState(LB_SELECTION);
  const [pop, setPop] = useState(null); // { top, left, text } | null

  // input mode
  const [draft, setDraft] = useState("");
  const [direction, setDirection] = useState("更地道");
  const [micOn, setMicOn] = useState(false);
  const [inputResult, setInputResult] = useState(false);

  // collection window
  const [collOpen, setCollOpen] = useState(false);
  const [collFilter, setCollFilter] = useState("全部");
  const [collQuery, setCollQuery] = useState("");

  const [toast, setToast] = useState("");
  const toastTimer = useRef(null);
  const loadTimer = useRef(null);

  const flash = useCallback((t) => {
    setToast(t);
    clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(""), 1600);
  }, []);

  // whether closing on click-outside is allowed: only when "light/empty"
  const hasContent =
    mode === "selection"
      ? true /* selection always shows a default result panel = content */
      : !!(draft.trim() || inputResult);
  const canCloseOnOutside = !pinned && !hasContent;

  const doClose = useCallback(() => {
    if (loadTimer.current) { clearTimeout(loadTimer.current); setLoading(false); }
    setOpen(false);
    setPinned(false);
  }, []);

  // pick an action → brief loading, then content
  const pickAction = useCallback((id) => {
    if (id === "collect") {
      flash("已收藏到「收藏」");
      return;
    }
    setAction(id);
    setLoading(true);
    clearTimeout(loadTimer.current);
    loadTimer.current = setTimeout(() => setLoading(false), 480);
  }, [flash]);

  // open in a given mode. opts: { text, pos } from a live text selection
  const openSelection = useCallback((opts) => {
    setMode("selection");
    setOpen(true);
    setAction(DEFAULT_ACTION);
    if (opts && opts.text) {
      setSelection({ text: opts.text, app: "Safari", doc: "Nature · Neuroscience" });
    }
    if (opts && opts.pos) {
      setPanelPos(opts.pos);
    }
    setPop(null);
    window.getSelection && window.getSelection().removeAllRanges();
    setLoading(true);
    clearTimeout(loadTimer.current);
    loadTimer.current = setTimeout(() => setLoading(false), 480);
  }, []);

  // live text selection inside the doc window → surface the pop button
  const onDocSelect = useCallback(() => {
    const selObj = window.getSelection();
    const text = selObj ? selObj.toString().trim() : "";
    if (!text || text.length < 2) { setPop(null); return; }
    const range = selObj.getRangeAt(0);
    const rect = range.getBoundingClientRect();
    if (!rect.width && !rect.height) { setPop(null); return; }
    // place pop just above the selection's end, clamped to viewport
    const left = Math.min(Math.max(rect.right - 16, 12), window.innerWidth - 130);
    const top = Math.max(rect.top - 44, 36);
    setPop({ top, left, text, anchor: { top: rect.bottom + 10, left: Math.min(rect.left, window.innerWidth - 740) } });
  }, []);

  const openInput = useCallback(() => {
    setMode("input");
    setOpen(true);
    setInputResult(false);
  }, []);

  // global hotkey ⌘. (toggle) and Esc (close)
  useEffect(() => {
    const onKey = (e) => {
      if (e.key === "Escape") {
        if (collOpen) { setCollOpen(false); return; }
        if (open) {
          if (pinned) { setPinned(false); flash("已取消固定，按 Esc 再次关闭"); return; }
          doClose();
        }
        return;
      }
      // ⌘.  → toggle Lingobar (再按快捷键)
      if (e.key === "." && e.metaKey) {
        e.preventDefault();
        if (open) doClose();
        else openSelection();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, pinned, collOpen, doClose, openSelection, flash]);

  // input-mode submit (改写)
  const submitInput = useCallback(() => {
    setLoading(true);
    clearTimeout(loadTimer.current);
    loadTimer.current = setTimeout(() => { setLoading(false); setInputResult(true); }, 600);
  }, []);

  // toggle voice (语音) — fills draft after a beat
  const toggleMic = useCallback(() => {
    setMicOn((on) => {
      if (!on) {
        setTimeout(() => {
          setDraft(LB_INPUT.draft);
          setMicOn(false);
        }, 1100);
        return true;
      }
      return false;
    });
  }, []);

  const grammarDisabled = false; // selection is English → 语法 available

  // drag the selection layer via the pill handle / pill body
  const onDragStart = useCallback((e) => {
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

  const pickRail = useCallback((key, val) => {
    setRailSel((s) => ({ ...s, [key]: val }));
    setLoading(true);
    clearTimeout(loadTimer.current);
    loadTimer.current = setTimeout(() => setLoading(false), 360);
  }, []);

  // bar position (near selection in the doc window)
  const barStyle = mode === "selection"
    ? { top: panelPos.top, left: panelPos.left }
    : { top: 220, left: "50%", transform: "translateX(-50%)" };

  return (
    <div className="stage" data-scheme={scheme}>
      <div className="wallpaper"><div className="wallpaper-grain" /></div>

      {/* macOS menu bar */}
      <div className="menubar">
        <span className="mb-logo"></span>
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span>
        <span className="mb-item">编辑</span>
        <span className="mb-item">视图</span>
        <span className="mb-item">收藏</span>
        <div className="mb-right">
          <span>⌘.</span>
          <span className="mono">周日 14:06</span>
          <span>🔋 86%</span>
        </div>
      </div>

      <SceneHint mode={mode} />

      {/* reading document window — the source app */}
      <DocWindow
        onTriggerSelection={openSelection}
        onSelect={onDocSelect}
        active={open && mode === "selection"}
      />

      {/* pop button that surfaces on a live text selection (划词唤起) */}
      {pop && !(open && mode === "selection") && (
        <button
          className="pop-trigger"
          style={{ top: pop.top, left: pop.left }}
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => openSelection({ text: pop.text, pos: pop.anchor })}
        >
          <LBIcon name="spark" size={14} /> Lingobar
        </button>
      )}

      {/* collection window toggle button on the dock-ish area is via switcher */}
      {collOpen && (
        <CollectionWindow
          filter={collFilter} onFilter={setCollFilter}
          query={collQuery} onQuery={setCollQuery}
          onClose={() => setCollOpen(false)}
        />
      )}

      {/* the Lingobar floating layer */}
      {open && (
        <>
          {/* click-catcher: only closes when state is "light" */}
          <div
            style={{ position: "absolute", inset: 0, zIndex: 15 }}
            onMouseDown={() => { if (canCloseOnOutside) doClose(); else flash("有内容时点击外部不关闭"); }}
          />
          <div
            className={"lb " + (mode === "selection" ? "sel" : "inp") + (pinned ? " is-pinned" : "") + (dragging ? " is-dragging" : "")}
            style={{ ...barStyle, zIndex: 20 }}
            onMouseDown={(e) => e.stopPropagation()}
          >
            {mode === "selection" ? (
              <>
                <LBPill
                  selection={selection}
                  onClose={doClose}
                  onPin={() => { setPinned((p) => !p); flash(pinned ? "已取消固定" : "已固定，点击外部不关闭"); }}
                  pinned={pinned}
                  onDragStart={onDragStart}
                  dragging={dragging}
                />
                <LBPanel
                  actionId={action}
                  action={action}
                  onPick={pickAction}
                  grammarDisabled={grammarDisabled}
                  loading={loading}
                  onCopy={() => flash("已复制")}
                  onCollect={() => flash("已收藏到「收藏」")}
                  onMore={() => flash("生成更多内容…")}
                  onClose={doClose}
                  onPlay={() => flash("▶ 播放发音")}
                  railSel={railSel}
                  onRailPick={pickRail}
                />
              </>
            ) : (
              <>
                <LBInput
                  value={draft}
                  onChange={setDraft}
                  onSubmit={submitInput}
                  micOn={micOn}
                  onMic={toggleMic}
                  onClose={doClose}
                />
                {loading && (
                  <div className="lb-surface lb-panel">
                    <div className="lb-loading"><span className="lb-spinner" /> 正在改写…</div>
                  </div>
                )}
                {!loading && inputResult && (
                  <LBInputResult
                    direction={direction}
                    onDirection={(d) => { setDirection(d); submitInput(); }}
                    onCopy={() => flash("已复制")}
                    onCollect={() => flash("已收藏到「收藏」")}
                    onMore={() => flash("生成更多版本…")}
                  />
                )}
              </>
            )}
          </div>
        </>
      )}

      <LBToast text={toast} />

      {/* in-page control: scheme switcher + mode/collection toggles */}
      <Switcher
        scheme={scheme} onScheme={setScheme}
        mode={mode} open={open}
        onSelection={openSelection}
        onInput={openInput}
        collOpen={collOpen}
        onColl={() => setCollOpen((c) => !c)}
      />
    </div>
  );
}

/* ---------- the reading document window ---------- */
function DocWindow({ onTriggerSelection, onSelect, active }) {
  return (
    <div className="docwin">
      <div className="docwin-bar">
        <span className="tl r" /><span className="tl y" /><span className="tl g" />
        <span className="docwin-title">Memory &amp; Sleep — Nature</span>
        <span className="docwin-url">nature.com</span>
      </div>
      <div className="docbody" onMouseUp={onSelect}>
        <div className="kicker">Neuroscience</div>
        <h1>How sleep rewires what we remember</h1>
        <div className="byline">By E. Hartmann · 8 min read</div>
        <p>For decades, the textbook story was simple: the brain replays the day's events during deep sleep, quietly filing them into long-term storage.</p>
        <p>
          A new study complicates that picture.{" "}
          <span className="sel" title="已选中：点击或选词唤起">
            The findings call into question long-held assumptions about how memory consolidates during sleep.
          </span>{" "}
          Instead of a single tidy process, the authors describe competing waves of activity that can both strengthen and weaken the same memory across a single night.
        </p>
        <p>The implication is unsettling for anyone who has trusted a good night's rest to lock in what they learned the day before.</p>
        {!active && (
          <p style={{ fontFamily: "-apple-system, sans-serif", fontSize: 13, color: "#a06a3c", background: "rgba(192,103,60,.08)", padding: "10px 12px", borderRadius: 10 }}>
            ↑ 用鼠标选中任意文字，旁边会冒出 Lingobar 按钮，点它进入选区模式。
          </p>
        )}
      </div>
    </div>
  );
}

function SceneHint({ mode }) {
  return (
    <div className="scene-hint">
      <span className="ttl">{mode === "selection" ? "有选区 · 默认翻译" : "无选区 · 输入改写"}</span>
      <span className="sub">⌘. 唤起 / 关闭 · Esc 关闭</span>
    </div>
  );
}

/* ---------- in-page scheme switcher + mode toggles ---------- */
function Switcher({ scheme, onScheme, mode, open, onSelection, onInput, collOpen, onColl }) {
  return (
    <div className="switcher">
      {LB_SCHEMES.map((s) => (
        <button key={s.id} className="sw-opt" data-active={scheme === s.id} onClick={() => onScheme(s.id)}>
          <span className="sw-dot" style={{ background: s.swatch }} />
          <span className="sw-text">
            <span className="sw-name">{s.name}</span>
            <span className="sw-blurb">{s.blurb}</span>
          </span>
        </button>
      ))}
      <span className="sw-sep" />
      <button className="sw-mode" data-active={open && mode === "selection"} onClick={onSelection} title="有选区模式">
        <LBIcon name="translate" size={15} /> 选区
      </button>
      <button className="sw-mode" data-active={open && mode === "input"} onClick={onInput} title="无选区输入模式">
        <LBIcon name="rewrite" size={15} /> 输入
      </button>
      <button className="sw-mode" data-active={collOpen} onClick={onColl} title="收藏库">
        <LBIcon name="collection" size={15} /> 收藏
      </button>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
