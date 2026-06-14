// bar.jsx — presentational pieces of the Lingobar floating layer.
// Pure components: props in, callbacks out. App owns all state.

const { useRef, useEffect } = React;

/* ---------- top pill: selection summary + tool cluster (pin/drag/close) ---------- */
function LBPill({ selection, onClose, onPin, pinned, onDragStart, dragging }) {
  const startDrag = (e) => { if (e.target.closest("button")) return; onDragStart && onDragStart(e); };
  return (
    <div className="lb-surface lb-pill is-grab" onMouseDown={startDrag}>
      <div className="lb-src">
        <div className="lb-src-meta">
          <span>{selection.app}</span>
          <span className="lb-src-dot" />
          <span>{selection.doc}</span>
        </div>
        <div className="lb-src-text" lang="en">{selection.text}</div>
      </div>
      <div className="lb-tools">
        <button className={"lb-iconbtn drag-handle" + (dragging ? " on" : "")} title="拖动" onMouseDown={onDragStart}>
          <LBIcon name="drag" size={15} />
        </button>
        <button className={"lb-iconbtn" + (pinned ? " on" : "")} title={pinned ? "已固定" : "固定"} onClick={onPin}>
          <LBIcon name="pin" size={15} />
        </button>
        <button className="lb-iconbtn" title="关闭 (Esc)" onClick={onClose}>
          <LBIcon name="close" size={15} />
        </button>
      </div>
    </div>
  );
}

/* ---------- action bar: text chips, wrapping grid (中文文字优先) ---------- */
function LBActions({ active, onPick, grammarDisabled }) {
  return (
    <div className="lb-actionbar">
      {LB_ACTIONS.map((a) => {
        const disabled = a.id === "grammar" && grammarDisabled;
        return (
          <button
            key={a.id}
            className="lb-act"
            data-active={active === a.id}
            data-disabled={disabled}
            title={disabled ? "语法仅支持英文内容" : a.label}
            onClick={() => !disabled && onPick(a.id)}
          >
            <LBIcon name={a.icon} size={15} /> {a.label}
          </button>
        );
      })}
    </div>
  );
}

/* ---------- per-action result bodies ---------- */
function TranslateBody({ b }) {
  return (
    <div>
      <div className="tr-gloss" lang="zh">{b.gloss}</div>
      <div className="tr-key">
        <span className="k" lang="en">{b.key}</span>
        <span className="kz" lang="zh">{b.keyZh}</span>
      </div>
      <div className="tr-note" lang="zh">{b.note}</div>
    </div>
  );
}

function GrammarBody({ b }) {
  return (
    <div>
      {b.blocks.map((blk, i) => (
        <div className="gr-block" key={i}>
          <div className="gr-role">{blk.role}</div>
          <div>
            <div className="gr-text" lang="en">{blk.text}</div>
            <div className="gr-hint" lang="zh">{blk.hint}</div>
          </div>
        </div>
      ))}
      <div className="gr-pattern">
        <div className="lbl">可复用句型</div>
        <div className="pt" lang="en">{b.pattern}</div>
        <div className="ptz" lang="zh">{b.patternZh}</div>
      </div>
    </div>
  );
}

function RewriteBody({ b }) {
  return (
    <div>
      <div className="rw-primary" lang="en">{b.primary}</div>
      <div style={{ marginTop: 8 }}>
        {b.variants.map((v, i) => (
          <div className="rw-var" key={i}>
            <span className="rw-tone">{v.tone}</span>
            <span className="rw-var-text" lang="en">{v.text}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function ExamplesBody({ b }) {
  // emphasise the shared collocation in each example
  const mark = (s) =>
    s.split(/(calls? into question)/gi).map((part, i) =>
      /call/i.test(part) ? <em key={i}>{part}</em> : part
    );
  return (
    <div>
      <div className="ex-lead" lang="zh">{b.lead}</div>
      {b.items.map((it, i) => (
        <div className="ex-item" key={i}>
          <span className="n">{i + 1}</span>
          <span lang="en">{mark(it)}</span>
        </div>
      ))}
    </div>
  );
}

function PronounceBody({ b, onPlay }) {
  return (
    <div>
      <div className="pr-wrap">
        <button className="pr-play" onClick={onPlay} title="播放">
          <LBIcon name="play" size={20} />
        </button>
        <div>
          <div className="pr-word" lang="en">{b.word}</div>
          <div className="pr-ipa">{b.ipa}</div>
          <div className="pr-syll">
            {b.syllables.map((s, i) => (
              <span key={i} data-stress={i === 1}>{s}</span>
            ))}
          </div>
        </div>
      </div>
      <div className="pr-stress" lang="zh">{b.stress}</div>
    </div>
  );
}

function LBResultBody({ actionId, onPlay }) {
  const r = LB_RESULTS[actionId];
  if (!r) return null;
  const b = r.body;
  switch (b.kind) {
    case "translate": return <TranslateBody b={b} />;
    case "grammar": return <GrammarBody b={b} />;
    case "rewrite": return <RewriteBody b={b} />;
    case "examples": return <ExamplesBody b={b} />;
    case "pronounce": return <PronounceBody b={b} onPlay={onPlay} />;
    default: return null;
  }
}

/* ---------- horizontal secondary-control bar (二次操作) ---------- */
function LBControlBar({ actionId, onMore, railSel, onRailPick }) {
  const r = LB_RESULTS[actionId];
  if (!r || !r.rail) return null;
  return (
    <div className="lb-ctrlbar">
      {r.rail.groups.map((g, gi) => (
        <div className="lb-ctrl-group" key={gi}>
          <span className="lbl">{g.label}</span>
          <div className="lb-ctrl-chips">
            {g.items.map((it) => {
              const active = (railSel[actionId + ":" + gi] ?? g.active) === it;
              return (
                <button key={it} className="lb-ctrl-chip" data-active={active} onClick={() => onRailPick(actionId + ":" + gi, it)}>
                  {it}
                </button>
              );
            })}
          </div>
        </div>
      ))}
      <div className="lb-ctrl-spacer" />
      <button className="lb-ctrl-more" onClick={onMore}><LBIcon name="spark" size={14} /> {r.more}</button>
    </div>
  );
}

/* ---------- result panel: actions + result body + control bar + footer ---------- */
function LBPanel({ actionId, loading, action, onPick, grammarDisabled, onCopy, onCollect, onMore, onClose, onPlay, railSel, onRailPick }) {
  const r = LB_RESULTS[actionId];
  const showResult = actionId && actionId !== "collect";
  return (
    <div className="lb-surface lb-panel">
      <LBActions active={action} onPick={onPick} grammarDisabled={grammarDisabled} />
      {showResult && r && (
        <>
          <div className="lb-panel-title">
            <span className="dot" />
            {r.title}
          </div>
          {loading ? (
            <div className="lb-loading" style={{ minHeight: 176 }}>
              <span className="lb-spinner" />
              正在生成…
            </div>
          ) : (
            <>
              <div className="lb-panel-body">
                <LBResultBody actionId={actionId} onPlay={onPlay} />
              </div>
              <LBControlBar actionId={actionId} onMore={onMore} railSel={railSel} onRailPick={onRailPick} />
              <div className="lb-foot">
                <button className="lb-foot-btn" onClick={onCopy}>
                  <LBIcon name="copy" size={15} /> 复制
                </button>
                <button className="lb-foot-btn" onClick={onCollect}>
                  <LBIcon name="star" size={15} /> 收藏
                </button>
              </div>
            </>
          )}
        </>
      )}
    </div>
  );
}

/* ---------- input mode: the PILL is the input field ---------- */
function LBInput({ value, onChange, onSubmit, micOn, onMic, onClose }) {
  const ref = useRef(null);
  useEffect(() => {
    if (ref.current) {
      ref.current.style.height = "auto";
      ref.current.style.height = Math.min(ref.current.scrollHeight, 110) + "px";
      ref.current.focus();
    }
  }, [value]);
  const empty = !value.trim();
  return (
    <div className="lb-surface lb-input-pill">
      <textarea
        ref={ref}
        className="lb-input"
        rows={1}
        placeholder="输入中文 / 英文 / 粗糙想法，按 ⏎ 改写成自然英文"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); if (!empty) onSubmit(); }
        }}
      />
      <div className="lb-input-actions">
        <button className="lb-mic" data-on={micOn} title="语音输入" onClick={onMic}>
          <LBIcon name="mic" size={17} />
        </button>
        <button className="lb-send" data-empty={empty} title="改写 (⏎)" onClick={() => !empty && onSubmit()}>
          <LBIcon name="arrowRight" size={17} />
        </button>
        <button className="lb-iconbtn" title="关闭 (Esc)" onClick={onClose} style={{ width: 32, height: 32 }}>
          <LBIcon name="close" size={16} />
        </button>
      </div>
    </div>
  );
}

/* ---------- input-mode result (after 改写) ---------- */
function LBInputResult({ direction, onDirection, onCopy, onCollect, onMore }) {
  const r = LB_INPUT.result;
  return (
    <div className="lb-surface lb-panel">
      <div className="lb-panel-title"><span className="dot" /> 改写 · 自然英文</div>
      <div className="lb-panel-body">
        <div className="rw-primary" lang="en">{r.primary}</div>
        <div style={{ marginTop: 8 }}>
          {r.variants.map((v, i) => (
            <div className="rw-var" key={i}>
              <span className="rw-tone">{v.tone}</span>
              <span className="rw-var-text" lang="en">{v.text}</span>
            </div>
          ))}
        </div>
      </div>
      {/* control bar — 改写方向, symmetric with selection-mode control bar */}
      <div className="lb-ctrlbar">
        <div className="lb-ctrl-group">
          <span className="lbl">方向</span>
          <div className="lb-ctrl-chips">
            {LB_INPUT.directions.map((d) => (
              <button key={d} className="lb-ctrl-chip" data-active={direction === d} onClick={() => onDirection(d)}>
                {d}
              </button>
            ))}
          </div>
        </div>
        <div className="lb-ctrl-spacer" />
        <button className="lb-ctrl-more" onClick={onMore}><LBIcon name="spark" size={14} /> 更多版本</button>
      </div>
      <div className="lb-foot">
        <button className="lb-foot-btn" onClick={onCopy}><LBIcon name="copy" size={15} /> 复制</button>
        <button className="lb-foot-btn" onClick={onCollect}><LBIcon name="star" size={15} /> 收藏</button>
      </div>
    </div>
  );
}

/* ---------- toast ---------- */
function LBToast({ text }) {
  if (!text) return null;
  return (
    <div className="lb-toast">
      <LBIcon name="check" size={14} /> {text}
    </div>
  );
}

/* ---------- collection window ---------- */
function CollectionWindow({ filter, onFilter, query, onQuery, onClose }) {
  const items = LB_COLLECTION.filter((it) => {
    const okType = filter === "全部" || it.type === filter;
    const okQ = !query || (it.text + it.meta).toLowerCase().includes(query.toLowerCase());
    return okType && okQ;
  });
  return (
    <div className="collwin">
      <div className="coll-head">
        <div className="coll-title">
          <LBIcon name="collection" size={18} /> 收藏
        </div>
        <span className="coll-count">{items.length} / {LB_COLLECTION.length}</span>
        <div style={{ flex: 1 }} />
        <button className="lb-iconbtn" title="关闭" onClick={onClose}><LBIcon name="close" size={15} /></button>
      </div>
      <div className="coll-search">
        <LBIcon name="search" size={15} />
        <input placeholder="搜索收藏…" value={query} onChange={(e) => onQuery(e.target.value)} />
      </div>
      <div className="coll-filters">
        {LB_COLLECTION_FILTERS.map((f) => (
          <button key={f} className="coll-filter" data-active={filter === f} onClick={() => onFilter(f)}>
            {f}
          </button>
        ))}
      </div>
      <div className="coll-list">
        {items.map((it, i) => (
          <div className="coll-item" key={i}>
            <span className="coll-type">{it.type}</span>
            <div className="coll-main">
              <div className="coll-text" lang={/[a-zA-Z]/.test(it.text[0]) ? "en" : "zh"}>{it.text}</div>
              <div className="coll-meta">
                <span>{it.meta}</span>
                <span className="src">{it.src}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, {
  LBPill, LBActions, LBPanel, LBControlBar, LBInput, LBInputResult, LBToast, CollectionWindow,
});
