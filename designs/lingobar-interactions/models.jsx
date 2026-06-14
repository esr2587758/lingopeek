// models.jsx — four interaction models. Shared result bodies + four shells.
// One visual language; four genuinely different ways to surface the same actions.

const { useState, useRef, useEffect } = React;

/* ============ shared result bodies (reused by every model) ============ */
function RBody({ actionId, onPlay }) {
  const r = LB_RESULTS[actionId];
  if (!r) return null;
  const b = r.body;
  if (b.kind === "translate")
    return (
      <div className="rb">
        <div className="rb-gloss" lang="zh">{b.gloss}</div>
        <div className="rb-key"><span className="k" lang="en">{b.key}</span><span className="kz" lang="zh">{b.keyZh}</span></div>
        <div className="rb-note" lang="zh">{b.note}</div>
      </div>
    );
  if (b.kind === "grammar")
    return (
      <div className="rb">
        {b.blocks.map((blk, i) => (
          <div className="gr-block" key={i}>
            <div className="gr-role">{blk.role}</div>
            <div><div className="gr-text" lang="en">{blk.text}</div><div className="gr-hint" lang="zh">{blk.hint}</div></div>
          </div>
        ))}
        <div className="gr-pattern">
          <div className="lbl">可复用句型</div>
          <div className="pt" lang="en">{b.pattern}</div>
          <div className="ptz" lang="zh">{b.patternZh}</div>
        </div>
      </div>
    );
  if (b.kind === "rewrite")
    return (
      <div className="rb">
        <div className="rw-primary" lang="en">{b.primary}</div>
        <div style={{ marginTop: 8 }}>
          {b.variants.map((v, i) => (
            <div className="rw-var" key={i}><span className="rw-tone">{v.tone}</span><span className="rw-var-text" lang="en">{v.text}</span></div>
          ))}
        </div>
      </div>
    );
  if (b.kind === "examples") {
    const mark = (s) => s.split(/(calls? into question)/gi).map((part, i) => (/call/i.test(part) ? <em key={i}>{part}</em> : part));
    return (
      <div className="rb">
        <div className="ex-lead" lang="zh">{b.lead}</div>
        {b.items.map((it, i) => (
          <div className="ex-item" key={i}><span className="n">{i + 1}</span><span lang="en">{mark(it)}</span></div>
        ))}
      </div>
    );
  }
  if (b.kind === "pronounce")
    return (
      <div className="rb">
        <div className="pr-wrap">
          <button className="pr-play" onClick={onPlay} title="播放"><LBIcon name="play" size={20} /></button>
          <div>
            <div className="pr-word" lang="en">{b.word}</div>
            <div className="pr-ipa">{b.ipa}</div>
            <div className="pr-syll">{b.syllables.map((s, i) => <span key={i} data-stress={i === 1}>{s}</span>)}</div>
          </div>
        </div>
        <div className="pr-stress" lang="zh">{b.stress}</div>
      </div>
    );
  return null;
}

// the footer actions row shared shape
function FootRow({ actionId, onCopy, onCollect, onMore }) {
  const r = LB_RESULTS[actionId];
  return (
    <div className="foot">
      <button className="foot-btn" onClick={onCopy}><LBIcon name="copy" size={15} /> 复制</button>
      <button className="foot-btn" onClick={onCollect}><LBIcon name="star" size={15} /> 收藏</button>
      <div className="foot-spacer" />
      <button className="foot-btn primary" onClick={onMore}><LBIcon name="spark" size={15} /> {r.more}</button>
    </div>
  );
}

// actions excluding 收藏 (which is an instant action, not a panel)
const PANEL_ACTIONS = LB_ACTIONS.filter((a) => a.id !== "collect");

/* =====================================================================
   MODEL 1 — RADIAL  (径向环形)
   Petals fan out around the selection; pick one → result card.
   ===================================================================== */
function RadialModel({ origin, action, loading, onPick, onClose, onCopy, onCollect, onMore, onPlay, flash }) {
  const acts = LB_ACTIONS; // include 收藏 as a petal
  const N = acts.length;
  const R = 96;
  const startAngle = -90; // top
  return (
    <>
      <div className="radial" style={{ left: origin.x, top: origin.y }}>
        <div className="radial-center" title="按 Esc 关闭" onClick={onClose}>
          <LBIcon name="translate" size={22} />
        </div>
        {acts.map((a, i) => {
          const ang = (startAngle + (360 / N) * i) * (Math.PI / 180);
          const x = Math.cos(ang) * R;
          const y = Math.sin(ang) * R;
          const disabled = a.id === "grammar" && false;
          return (
            <button
              key={a.id}
              className="radial-petal"
              data-disabled={disabled}
              style={{ left: x, top: y, "--fromx": "-50%", "--fromy": "-50%", animationDelay: `${i * 28}ms` }}
              title={a.label}
              onClick={() => onPick(a.id)}
            >
              <LBIcon name={a.icon} size={18} />
              <span>{a.label}</span>
            </button>
          );
        })}
        <div className="radial-hint">围绕选区一圈，移动到动作松手即触发</div>
      </div>

      {action && (
        <div className="radial-card" style={{ left: origin.x + 150, top: Math.max(70, origin.y - 120) }}>
          <div className="cmd-preview-title" style={{ padding: "12px 16px 0" }}>
            <span className="dot" /> {LB_RESULTS[action].title}
          </div>
          <div className="rc-scroll" style={{ padding: "6px 16px 12px" }}>
            {loading ? (
              <div className="loading-row"><span className="spinner" /> 正在生成…</div>
            ) : (
              <RBody actionId={action} onPlay={onPlay} />
            )}
          </div>
          {!loading && <FootRow actionId={action} onCopy={onCopy} onCollect={onCollect} onMore={onMore} />}
        </div>
      )}
    </>
  );
}

/* =====================================================================
   MODEL 2 — COMMAND  (Raycast 式命令列表)
   Selection on top, vertical action list, ↑↓ + ⏎, live preview pane.
   ===================================================================== */
function CommandModel({ action, loading, onPick, onClose, onCopy, onCollect, onMore, onPlay }) {
  return (
    <div className="cmd">
      <div className="cmd-search">
        <LBIcon name="translate" size={18} style={{ color: "var(--accent-text)", flex: "none" }} />
        <div className="q">
          <div className="label"><span>{LB_SELECTION.app}</span><span>·</span><span>{LB_SELECTION.doc}</span></div>
          <div className="text" lang="en">{LB_SELECTION.text}</div>
        </div>
        <button className="iconbtn" onClick={onClose} title="关闭 (Esc)"><LBIcon name="close" size={15} /></button>
      </div>
      <div className="cmd-body">
        <div className="cmd-list">
          <div className="cmd-group-label">语言动作</div>
          {LB_ACTIONS.map((a, i) => {
            const disabled = a.id === "grammar" && false;
            return (
              <div
                key={a.id}
                className="cmd-row"
                data-active={action === a.id}
                data-disabled={disabled}
                onClick={() => onPick(a.id)}
              >
                <LBIcon name={a.icon} size={16} />
                <span className="lbl">{a.label}</span>
                <span className="key">{i < 9 ? `⌘${i + 1}` : ""}</span>
              </div>
            );
          })}
        </div>
        <div className="cmd-preview">
          {action === "collect" ? (
            <div className="loading-row" style={{ color: "var(--accent-text)" }}><LBIcon name="check" size={15} /> 已收藏到「收藏」</div>
          ) : (
            <>
              <div className="cmd-preview-title"><span className="dot" /> {LB_RESULTS[action].title}</div>
              {loading ? <div className="loading-row"><span className="spinner" /> 正在生成…</div> : <RBody actionId={action} onPlay={onPlay} />}
            </>
          )}
        </div>
      </div>
      <div className="cmd-foot">
        <span><span className="helper" /></span>
        <span style={{ display: "inline-flex", gap: 4, alignItems: "center" }}>
          <span className="key" style={{ fontFamily: "var(--mono)" }}>↑↓</span> 选择
        </span>
        <span style={{ display: "inline-flex", gap: 4, alignItems: "center" }}>
          <span className="key" style={{ fontFamily: "var(--mono)" }}>⏎</span> 执行
        </span>
        <div className="spacer" />
        {action !== "collect" && (
          <>
            <span className="act" onClick={onCopy}><LBIcon name="copy" size={14} /> 复制</span>
            <span className="act" onClick={onCollect}><LBIcon name="star" size={14} /> 收藏</span>
            <span className="act" onClick={onMore}><LBIcon name="spark" size={14} /> {LB_RESULTS[action].more}</span>
          </>
        )}
      </div>
    </div>
  );
}

/* =====================================================================
   MODEL 3 — INLINE  (内联注释层)
   A small chip tab sits under the selection; choosing an action grows
   an annotation card anchored to the line, like the text gained a layer.
   ===================================================================== */
function InlineModel({ anchor, action, loading, onPick, onClose, onCopy, onCollect, onMore, onPlay }) {
  // anchor: {x,y,noteX,noteY}
  return (
    <div className="inline-layer">
      {/* chip tab — only the panel actions + collect, compact */}
      <div className="inline-tab" style={{ left: anchor.x, top: anchor.y }}>
        {LB_ACTIONS.map((a) => {
          const disabled = a.id === "grammar" && false;
          return (
            <button
              key={a.id}
              className="inline-chip"
              data-active={action === a.id}
              data-disabled={disabled}
              title={a.label}
              onClick={() => onPick(a.id)}
            >
              <LBIcon name={a.icon} size={16} />
            </button>
          );
        })}
        <button className="inline-chip" title="关闭" onClick={onClose}><LBIcon name="close" size={15} /></button>
      </div>

      {action && action !== "collect" && (
        <div className="inline-note" style={{ left: anchor.noteX, top: anchor.noteY }}>
          <div className="inline-note-rail" />
          <div className="inline-note-inner">
            <div className="inline-note-head">
              <span className="tag">{LB_RESULTS[action].title}</span>
              <div className="tabs">
                {PANEL_ACTIONS.map((a) => {
                  const disabled = a.id === "grammar" && false;
                  return (
                    <button key={a.id} className="mini" data-active={action === a.id} data-disabled={disabled} onClick={() => onPick(a.id)}>{a.label}</button>
                  );
                })}
              </div>
            </div>
            {loading ? <div className="loading-row"><span className="spinner" /> 正在生成…</div> : <RBody actionId={action} onPlay={onPlay} />}
            {!loading && (
              <div className="inline-note-foot">
                <span className="a" onClick={onCopy}><LBIcon name="copy" size={14} /> 复制</span>
                <span className="a" onClick={onCollect}><LBIcon name="star" size={14} /> 收藏</span>
                <div className="spacer" />
                <span className="a" onClick={onMore}><LBIcon name="spark" size={14} /> {LB_RESULTS[action].more}</span>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

/* =====================================================================
   MODEL 4 — PANEL  (pill + in-panel actions + horizontal control bar)
   Pill: selection summary + tool cluster only.
   Panel: action bar on top (3 switchable form variants) · result body ·
   horizontal secondary-control bar (was the right rail) · footer.
   ===================================================================== */

// the action bar — three form variants, switched via `variant`
function ActionBar({ variant, action, onPick }) {
  const overflowRef = useRef(null);
  const [menuOpen, setMenuOpen] = useState(false);
  useEffect(() => {
    if (!menuOpen) return;
    const h = (e) => { if (overflowRef.current && !overflowRef.current.contains(e.target)) setMenuOpen(false); };
    window.addEventListener("mousedown", h);
    return () => window.removeEventListener("mousedown", h);
  }, [menuOpen]);

  if (variant === "tile") {
    return (
      <div className="pm-actionbar v-tile">
        {LB_ACTIONS.map((a) => (
          <button key={a.id} className="a" data-active={action === a.id} onClick={() => onPick(a.id)}>
            <LBIcon name={a.icon} size={18} />
            <span>{a.label}</span>
          </button>
        ))}
      </div>
    );
  }
  if (variant === "overflow") {
    // primary = first 4 flat; rest in overflow menu
    const primary = LB_ACTIONS.slice(0, 4);
    const extra = LB_ACTIONS.slice(4);
    return (
      <div className="pm-actionbar v-overflow">
        {primary.map((a) => (
          <button key={a.id} className="a" data-active={action === a.id} onClick={() => onPick(a.id)}>
            <LBIcon name={a.icon} size={16} /> {a.label}
          </button>
        ))}
        <div className="more" ref={overflowRef}>
          <button className="more-btn" title="更多动作" onClick={() => setMenuOpen((o) => !o)}>
            <LBIcon name="grid" size={16} />
          </button>
          {menuOpen && (
            <div className="pm-overflow-menu">
              {extra.map((a) => (
                <div key={a.id} className="mi" data-active={action === a.id} onClick={() => { onPick(a.id); setMenuOpen(false); }}>
                  <LBIcon name={a.icon} size={15} /> {a.label}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    );
  }
  // default: text chips, wrapping grid
  return (
    <div className="pm-actionbar v-text">
      {LB_ACTIONS.map((a) => (
        <button key={a.id} className="a" data-active={action === a.id} onClick={() => onPick(a.id)}>
          <LBIcon name={a.icon} size={15} /> {a.label}
        </button>
      ))}
    </div>
  );
}

// horizontal secondary-control bar (former right rail)
function ControlBar({ actionId, onMore, railSel, onRailPick }) {
  const r = LB_RESULTS[actionId];
  if (!r || !r.rail) return null;
  return (
    <div className="pm-ctrlbar">
      {r.rail.groups.map((g, gi) => (
        <div className="pm-ctrl-group" key={gi}>
          <span className="lbl">{g.label}</span>
          <div className="pm-ctrl-chips">
            {g.items.map((it) => {
              const active = (railSel[actionId + ":" + gi] ?? g.active) === it;
              return (
                <button key={it} className="pm-ctrl-chip" data-active={active} onClick={() => onRailPick(actionId + ":" + gi, it)}>
                  {it}
                </button>
              );
            })}
          </div>
        </div>
      ))}
      <div className="pm-ctrl-spacer" />
      <button className="pm-ctrl-more" onClick={onMore}><LBIcon name="spark" size={14} /> {r.more}</button>
    </div>
  );
}

function PanelModel({ pos, selection, action, loading, onPick, onClose, onCopy, onCollect, onMore, onPlay, pinned, onPin, onDragStart, dragging, railSel, onRailPick, variant }) {
  const sel = selection || LB_SELECTION;
  const startDrag = (e) => { if (e.target.closest("button")) return; onDragStart(e); };
  const showResult = action && action !== "collect";
  return (
    <div className={"panelmodel" + (pinned ? " is-pinned" : "") + (dragging ? " is-dragging" : "")} style={pos}>
      {/* ---- top pill: summary + tools ---- */}
      <div className="pm-pill is-grab" onMouseDown={startDrag}>
        <div className="pm-src">
          <div className="pm-src-meta"><span>{sel.app}</span><span className="pm-src-dot" /><span>{sel.doc}</span></div>
          <div className="pm-src-text" lang="en">{sel.text}</div>
        </div>
        <div className="pm-tools">
          <button className={"iconbtn drag-handle" + (dragging ? " on" : "")} title="拖动" onMouseDown={onDragStart}>
            <LBIcon name="drag" size={15} />
          </button>
          <button className={"iconbtn" + (pinned ? " on" : "")} title={pinned ? "已固定" : "固定"} onClick={onPin}>
            <LBIcon name="pin" size={15} />
          </button>
          <button className="iconbtn" onClick={onClose} title="关闭 (Esc)"><LBIcon name="close" size={15} /></button>
        </div>
      </div>

      {/* ---- panel: actions + result + control bar + footer ---- */}
      <div className="pm-panel">
        <ActionBar variant={variant} action={action} onPick={onPick} />
        {showResult && (
          <>
            <div className="pm-panel-title"><span className="dot" /> {LB_RESULTS[action].title}</div>
            {loading ? (
              <div className="loading-row" style={{ padding: "18px", minHeight: 176 }}><span className="spinner" /> 正在生成…</div>
            ) : (
              <>
                <div className="pm-panel-body"><RBody actionId={action} onPlay={onPlay} /></div>
                <ControlBar actionId={action} onMore={onMore} railSel={railSel} onRailPick={onRailPick} />
                <div className="pm-leftfoot">
                  <button className="foot-btn" onClick={onCopy}><LBIcon name="copy" size={15} /> 复制</button>
                  <button className="foot-btn" onClick={onCollect}><LBIcon name="star" size={15} /> 收藏</button>
                </div>
              </>
            )}
          </>
        )}
      </div>
    </div>
  );
}

Object.assign(window, {
  RadialModel, CommandModel, InlineModel, PanelModel, RBody, FootRow, PANEL_ACTIONS,
});
