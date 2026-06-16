// cards.jsx — 语法可视化模块
const { useState, useRef, useLayoutEffect } = React;

// ---------- 成分图例 ----------
function RoleLegend({ hover, onHover }) {
  const used = ["subject", "predicate", "object", "attr", "adv", "conj"];
  return (
    <div className="gx-legend">
      {used.map((r) => (
        <span key={r} className="gx-legend-item" data-dim={hover && hover !== r || undefined}
          onMouseEnter={() => onHover && onHover(r)} onMouseLeave={() => onHover && onHover(null)}>
          <span className="gx-legend-dot" style={{ background: ROLES[r].color }} />
          {ROLES[r].zh}
        </span>
      ))}
    </div>
  );
}

// ---------- 1. 彩色标注句 ----------
function AnnotatedView({ hover, onHover }) {
  return (
    <div className="gx-annot">
      <div className="gx-annot-sentence" lang="en">
        {CHUNKS.map((c) => (
          <span key={c.id} className="gx-chunk" data-role={c.role}
            data-dim={hover && hover !== c.role || undefined}
            style={{ "--role-color": ROLES[c.role].color, "--role-hl": ROLES[c.role].hl }}
            onMouseEnter={() => onHover(c.role)} onMouseLeave={() => onHover(null)}>
            {c.text}
            <span className="gx-chunk-tag" style={{ background: ROLES[c.role].color }}>{c.label}</span>
          </span>
        ))}
      </div>
      <div className="gx-annot-notes">
        {CHUNKS.map((c) => (
          <div key={c.id} className="gx-note" data-dim={hover && hover !== c.role || undefined}>
            <span className="gx-note-bar" style={{ background: ROLES[c.role].color }} />
            <div>
              <span className="gx-note-label" style={{ color: ROLES[c.role].color }}>{c.label}</span>
              <span className="gx-note-text" lang="en">{c.text}</span>
              <div className="gx-note-zh">{c.note}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ---------- 2. 依存关系弧线（SVG） ----------
function DependencyView({ hover, onHover }) {
  const wrapRef = useRef(null);
  const tokRefs = useRef({});
  const [arcs, setArcs] = useState([]);
  const [w, setW] = useState(600);

  useLayoutEffect(() => {
    const wrap = wrapRef.current;
    if (!wrap) return;
    const measure = () => {
      const base = wrap.getBoundingClientRect();
      setW(base.width);
      const center = (id) => {
        const el = tokRefs.current[id];
        if (!el) return null;
        const r = el.getBoundingClientRect();
        return { x: r.left - base.left + r.width / 2, top: r.top - base.top };
      };
      const out = [];
      DEPS.forEach((d) => {
        const a = center(d.from), b = center(d.to);
        if (!a || !b) return;
        const x1 = a.x, x2 = b.x, top = Math.min(a.top, b.top);
        const span = Math.abs(x2 - x1);
        const lift = Math.min(20 + span * 0.22, 74);
        out.push({ ...d, x1, x2, y: top, lift });
      });
      setArcs(out);
    };
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(wrap);
    return () => ro.disconnect();
  }, []);

  const H = 90;
  return (
    <div className="gx-dep" ref={wrapRef}>
      <svg className="gx-dep-svg" width={w} height={H} style={{ overflow: "visible" }}>
        {arcs.map((a, i) => {
          const midx = (a.x1 + a.x2) / 2;
          const role = CHUNKS.find((c) => c.id === a.from)?.role || "conj";
          const col = ROLES[role].color;
          const dim = hover && hover !== role;
          const yb = H; // baseline
          const path = `M ${a.x1} ${yb} C ${a.x1} ${yb - a.lift}, ${a.x2} ${yb - a.lift}, ${a.x2} ${yb}`;
          return (
            <g key={i} className="gx-arc" data-dim={dim || undefined}>
              <path d={path} fill="none" stroke={col} strokeWidth="1.6" opacity={dim ? 0.2 : 0.85} />
              <polygon points={arrowHead(a.x2, yb, a.x2 > a.x1 ? -1 : 1)} fill={col} opacity={dim ? 0.2 : 0.85} />
              <rect x={midx - labelW(a.label) / 2} y={yb - a.lift - 9} width={labelW(a.label)} height="17" rx="6" fill="#1b1d27" stroke={col} strokeOpacity="0.4" opacity={dim ? 0.25 : 1} />
              <text x={midx} y={yb - a.lift + 3} textAnchor="middle" fontSize="10.5" fill={col} opacity={dim ? 0.3 : 1}>{a.label}</text>
            </g>
          );
        })}
      </svg>
      <div className="gx-dep-tokens" lang="en">
        {CHUNKS.map((c) => (
          <span key={c.id} ref={(el) => (tokRefs.current[c.id] = el)}
            className="gx-dep-tok" data-role={c.role} data-dim={hover && hover !== c.role || undefined}
            style={{ "--role-color": ROLES[c.role].color }}
            onMouseEnter={() => onHover(c.role)} onMouseLeave={() => onHover(null)}>
            {c.text}
          </span>
        ))}
      </div>
    </div>
  );
}
function arrowHead(x, y, dir) {
  // small triangle pointing down onto the baseline
  const s = 4;
  return `${x - s},${y - 7} ${x + s},${y - 7} ${x},${y - 1}`;
}
function labelW(t) { return Math.max(34, t.length * 12 + 12); }

// ---------- 3. 层次树 ----------
function TreeNode({ node, depth = 0 }) {
  const col = ROLES[node.role]?.color || "#b6bcc8";
  return (
    <div className="gx-tree-node" style={{ marginLeft: depth ? 18 : 0 }}>
      <div className="gx-tree-row" style={{ "--role-color": col }}>
        <span className="gx-tree-rail" style={{ background: col }} />
        <span className="gx-tree-label" style={{ color: col }}>{node.label}</span>
        <span className="gx-tree-text" lang="en">{node.text}</span>
      </div>
      {node.children && <div className="gx-tree-children">{node.children.map((c, i) => <TreeNode key={i} node={c} depth={depth + 1} />)}</div>}
    </div>
  );
}
function TreeView() {
  return <div className="gx-tree"><TreeNode node={TREE} /></div>;
}

// ---------- 4. 主干提取 ----------
function TrunkView() {
  return (
    <div className="gx-trunk">
      <div className="gx-trunk-core" lang="en">
        {TRUNK.core.map((t, i) => (
          <span key={i} className="gx-trunk-tok" style={{ "--role-color": ROLES[t.role].color, "--role-hl": ROLES[t.role].hl }}>
            {t.w}
          </span>
        ))}
      </div>
      <div className="gx-trunk-zh">{TRUNK.coreZh}</div>
      <div className="gx-trunk-dropped">
        <span className="lbl">已省略的修饰成分</span>
        {TRUNK.dropped.map((d, i) => <span key={i} className="gx-trunk-chip">{d}</span>)}
      </div>
    </div>
  );
}

// ---------- 知识模块 ----------
function CollocationCard({ c, onPlay }) {
  return (
    <div className="gx-colloc">
      <div className="gx-colloc-head">
        <span className="gx-colloc-phrase" lang="en">{c.phrase}</span>
        <span className="gx-colloc-pos">{c.pos}</span>
        <button className="gx-mini-play" title="发音" onClick={() => onPlay(c.phrase)}><LBIcon name="sound" size={14} /></button>
      </div>
      <div className="gx-colloc-zh">{c.zh}</div>
      <div className="gx-colloc-note">{c.note}</div>
      <div className="gx-colloc-eg" lang="en"><span className="eg-tag">e.g.</span> {c.example}</div>
    </div>
  );
}
function GrammarPointCard({ p }) {
  return (
    <div className="gx-point" style={{ "--pt-color": p.color }}>
      <div className="gx-point-head">
        <span className="gx-point-tag">{p.tag}</span>
        <span className="gx-point-title">{p.title}</span>
      </div>
      <div className="gx-point-body">{p.body}</div>
    </div>
  );
}

Object.assign(window, {
  RoleLegend, AnnotatedView, DependencyView, TreeView, TrunkView,
  CollocationCard, GrammarPointCard,
});
