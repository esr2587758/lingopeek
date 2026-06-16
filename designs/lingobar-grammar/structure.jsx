// structure.jsx — the two structure visualisations + shared pieces.
// ChartView: colour blocks laid out left→right with relation arcs beneath
//   (the imagegen concept). TreeView: the same parse as a nested clause tree.
// Both consume the structured model in data.jsx and never parse text.
// Pure presentational components; App owns level / labels / focus / view state.

const { useRef, useState, useLayoutEffect } = React;

/* helper: is a block/card active under the current focus? */
function isActive(focus, id, type) {
  if (!focus) return true;
  if (focus.ids && focus.ids.includes(id)) return true;
  if (focus.type && type === focus.type) return true;
  return false;
}

/* ---------- legend: colour key, doubles as a per-type highlighter ---------- */
function GLegend({ focus, onFocusType, types }) {
  return (
    <div className="g-legend">
      {types.map((t) => {
        const T = G_TYPES[t];
        const dim = focus && focus.type && focus.type !== t;
        return (
          <button
            key={t}
            className="g-legend-item"
            data-dim={dim || undefined}
            onMouseEnter={() => onFocusType(t)}
            onMouseLeave={() => onFocusType(null)}
            title={`高亮全部「${T.zh}」`}
          >
            <span className="g-legend-dot" style={{ background: T.solid }} />
            {T.zh}
          </button>
        );
      })}
    </div>
  );
}

/* ---------- a single colour block (used at top level + inside clause panel) ---------- */
function GBlock({ block, labels, focus, onFocusBlock, blockRef, small }) {
  const T = G_TYPES[block.type];
  const active = isActive(focus, block.id, block.type);
  return (
    <button
      ref={blockRef}
      className={"g-block" + (small ? " is-sm" : "") + (block.phrase ? " is-phrase" : "")}
      data-dim={focus && !active || undefined}
      style={{ "--c": T.solid, "--ct": T.text, "--tint": T.tint }}
      onMouseEnter={() => onFocusBlock(block)}
      onMouseLeave={() => onFocusBlock(null)}
    >
      <span className="g-block-word" lang="en">{block.text}</span>
      {labels && (
        <span className="g-block-tag">
          {T.zh}<span className="g-block-tag-easy">{T.easy}</span>
        </span>
      )}
    </button>
  );
}

/* ---------- the structure chart: blocks + relation arcs ---------- */
function ChartView({ level, labels, focus, onFocusBlock, onFocusType }) {
  const blocks = G_CHART[level];
  const rels = G_RELATIONS[level];
  const wrapRef = useRef(null);
  const refs = useRef({});
  const [arcs, setArcs] = useState([]);
  const [box, setBox] = useState({ w: 0, h: 0 });

  useLayoutEffect(() => {
    const wrap = wrapRef.current;
    if (!wrap) return;
    const measure = () => {
      const base = wrap.getBoundingClientRect();
      const at = (id) => {
        const el = refs.current[id];
        if (!el) return null;
        const r = el.getBoundingClientRect();
        return { x: r.left - base.left + r.width / 2, bottom: r.bottom - base.top, top: r.top - base.top };
      };
      const out = [];
      rels.forEach((d) => {
        const a = at(d.from), b = at(d.to);
        if (!a || !b) return;
        const baseY = Math.max(a.bottom, b.bottom) + 6;
        const span = Math.abs(b.x - a.x);
        const dip = baseY + Math.min(16 + span * 0.16, 46);
        out.push({ ...d, x1: a.x, y1: a.bottom + 2, x2: b.x, y2: b.bottom + 2, dip });
      });
      setArcs(out);
      setBox({ w: base.width, h: base.height });
    };
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(wrap);
    return () => ro.disconnect();
  }, [level, labels]);

  const setRef = (id) => (el) => { if (el) refs.current[id] = el; };

  return (
    <div className="g-chart" ref={wrapRef}>
      <svg className="g-arcs" width={box.w} height={box.h} aria-hidden="true">
        {arcs.map((a, i) => {
          const T = G_TYPES[G_CHART[level].find((b) => b.id === a.from)?.type] || G_TYPES.clause;
          const onEither = !focus || isActive(focus, a.from) || isActive(focus, a.to);
          const dim = focus && !onEither;
          const midx = (a.x1 + a.x2) / 2;
          const path = `M ${a.x1} ${a.y1} C ${a.x1} ${a.dip}, ${a.x2} ${a.dip}, ${a.x2} ${a.y2}`;
          return (
            <g key={i} opacity={dim ? 0.16 : 1}>
              <path d={path} fill="none" stroke={T.line}
                strokeWidth="1.6" strokeDasharray={a.dashed ? "3 3" : "none"} />
              <circle cx={a.x2} cy={a.y2} r="2.4" fill={T.line} />
              <g>
                <rect x={midx - relW(a.kind) / 2} y={a.dip - 8} width={relW(a.kind)} height="16" rx="8"
                  fill="var(--bg-solid)" stroke={T.line} strokeOpacity="0.5" />
                <text x={midx} y={a.dip + 3.5} textAnchor="middle" fontSize="10" fill={T.text}
                  fontFamily="-apple-system, 'PingFang SC', sans-serif">{a.kind}</text>
              </g>
            </g>
          );
        })}
      </svg>

      <div className="g-blockrow">
        {blocks.map((b) =>
          b.panel ? (
            <div key={b.id} className="g-clausepanel"
              data-dim={focus && !isActive(focus, b.id, "clause") || undefined}
              onMouseEnter={() => onFocusBlock(b)} onMouseLeave={() => onFocusBlock(null)}>
              <span className="g-clausepanel-tag">
                <span className="g-clausepanel-conj" lang="en">{b.conj}</span>{b.clauseKind}
              </span>
              <div className="g-clausepanel-inner" ref={setRef(b.id)}>
                {b.children.map((c) => (
                  <GBlock key={c.id} block={c} labels={labels} focus={focus} small
                    onFocusBlock={onFocusBlock} blockRef={setRef(c.id)} />
                ))}
              </div>
            </div>
          ) : (
            <GBlock key={b.id} block={b} labels={labels} focus={focus}
              onFocusBlock={onFocusBlock} blockRef={setRef(b.id)} />
          )
        )}
      </div>
    </div>
  );
}
function relW(t) { return Math.max(26, t.length * 11 + 12); }

/* ---------- nested clause tree ---------- */
function TreeNode({ node, focus, onFocusBlock, depth }) {
  const T = G_TYPES[node.type] || G_TYPES.clause;
  const active = !focus || (node.spans || []).some((s) => isActive(focus, s, node.type));
  return (
    <div className="g-tnode" style={{ "--c": T.solid, "--ct": T.text }}>
      <div className="g-trow" data-dim={focus && !active || undefined}
        onMouseEnter={() => onFocusBlock({ spans: node.spans, type: node.type })}
        onMouseLeave={() => onFocusBlock(null)}>
        <span className="g-trail" />
        <span className="g-tlabel">{node.role}<span className="g-tlabel-en">{node.roleEn}</span></span>
        <span className="g-ttext" lang="en">{node.summary}</span>
        {node.summaryZh && <span className="g-tzh">{node.summaryZh}</span>}
      </div>
      {node.children && (
        <div className="g-tchildren">
          {node.children.map((c, i) => (
            <TreeNode key={i} node={c} focus={focus} onFocusBlock={onFocusBlock} depth={depth + 1} />
          ))}
        </div>
      )}
    </div>
  );
}
function TreeView({ focus, onFocusBlock }) {
  return <div className="g-tree"><TreeNode node={G_TREE} focus={focus} onFocusBlock={onFocusBlock} depth={0} /></div>;
}

/* ---------- insight cards ---------- */
function InsightCards({ level, focus, onFocusCard }) {
  const cards = G_CARDS.filter((c) => level === "adv" || c.level === "easy");
  return (
    <div className="g-cards">
      {cards.map((c) => {
        const T = G_TYPES[c.type];
        const active = !focus || c.spans.some((s) => isActive(focus, s, c.type));
        return (
          <div key={c.id} className="g-card" data-dim={focus && !active || undefined}
            style={{ "--c": T.solid, "--ct": T.text, "--tint": T.tint }}
            onMouseEnter={() => onFocusCard(c)} onMouseLeave={() => onFocusCard(null)}>
            <div className="g-card-head">
              <span className="g-card-dot" />
              <span className="g-card-tag">{c.tag}</span>
              <span className="g-card-tagen">{c.tagEn}</span>
            </div>
            <div className="g-card-title">{c.title}</div>
            <div className="g-card-body">{c.body}</div>
          </div>
        );
      })}
    </div>
  );
}

/* ---------- phrase highlights row ---------- */
function PhraseRow({ focus, onFocusBlock }) {
  return (
    <div className="g-phrases">
      <span className="g-phrases-lbl"><LBIcon name="link2" size={13} /> 固定搭配</span>
      {G_PHRASES.map((p, i) => (
        <button key={i} className="g-phrase"
          data-dim={focus && !isActive(focus, p.span) || undefined}
          onMouseEnter={() => onFocusBlock({ spans: [p.span] })} onMouseLeave={() => onFocusBlock(null)}>
          <span lang="en">{p.text}</span>
          <span className="g-phrase-zh">{p.zh}</span>
        </button>
      ))}
    </div>
  );
}

Object.assign(window, {
  GLegend, GBlock, ChartView, TreeView, TreeNode, InsightCards, PhraseRow, isActive,
});
