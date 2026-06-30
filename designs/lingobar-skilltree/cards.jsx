// cards.jsx — 「语法星座」放射状布局 + 六边形 + 例句详情
const { useState, useMemo, useRef } = React;

// ---------- 放射状布局：根在中心，按子树叶子数分配角度扇区，深度 → 半径 ----------
function layoutRadial(nodes) {
  const byId = {}; nodes.forEach((n) => (byId[n.id] = { ...n, children: [] }));
  let root = null;
  nodes.forEach((n) => { if (n.parent) byId[n.parent].children.push(byId[n.id]); else root = byId[n.id]; });

  // 统计每个子树的叶子数（决定角度宽度）
  const leaves = (node) => {
    if (node.children.length === 0) return (node._leaves = 1);
    return (node._leaves = node.children.reduce((s, c) => s + leaves(c), 0));
  };
  leaves(root);

  const RING = 116; // 每层半径增量
  // 递归分配角度扇区 [a0,a1]
  const assign = (node, depth, a0, a1) => {
    node.depth = depth;
    node.angle = (a0 + a1) / 2;
    node.radius = depth * RING;
    let cur = a0;
    node.children.forEach((c) => {
      const span = (a1 - a0) * (c._leaves / node._leaves);
      assign(c, depth + 1, cur, cur + span);
      cur += span;
    });
  };
  assign(root, 0, 0, Math.PI * 2);

  const flat = Object.values(byId);
  // 极坐标 → 直角坐标
  flat.forEach((n) => {
    n.x = Math.cos(n.angle - Math.PI / 2) * n.radius;
    n.y = Math.sin(n.angle - Math.PI / 2) * n.radius;
  });

  // 碰撞外推：同环节点若太近，沿半径方向轻微外推（多轮松弛）
  const R = 30, MIND = R * 2 + 10;
  for (let iter = 0; iter < 60; iter++) {
    let moved = false;
    for (let i = 0; i < flat.length; i++) for (let j = i + 1; j < flat.length; j++) {
      const a = flat[i], b = flat[j];
      if (a.depth === 0 || b.depth === 0) continue;
      const dx = b.x - a.x, dy = b.y - a.y;
      const d = Math.hypot(dx, dy) || 0.01;
      if (d < MIND) {
        const push = (MIND - d) / 2;
        const ux = dx / d, uy = dy / d;
        // 深度大的那个多让一点（往外推）
        a.x -= ux * push * 0.5; a.y -= uy * push * 0.5;
        b.x += ux * push * 0.5; b.y += uy * push * 0.5;
        moved = true;
      }
    }
    if (!moved) break;
  }

  const maxR = Math.max(...flat.map((n) => Math.hypot(n.x, n.y) + R));
  const edges = [];
  flat.forEach((n) => n.children.forEach((c) => edges.push({ from: n, to: c })));
  return { nodes: flat, edges, extent: maxR, depthMax: Math.max(...flat.map(n => n.depth)) };
}

function hexPoints(cx, cy, r) {
  const pts = [];
  for (let i = 0; i < 6; i++) {
    const a = (Math.PI / 180) * (60 * i - 30); // pointy-top
    pts.push(`${(cx + r * Math.cos(a)).toFixed(1)},${(cy + r * Math.sin(a)).toFixed(1)}`);
  }
  return pts.join(" ");
}

// ---------- 概览 ----------
function OverviewHeader() {
  return (
    <div className="sk-overview">
      <div className="sk-ov-line"><span className="sk-ov-ic"><LBIcon name="eye" size={17} /></span>{OVERVIEW.line}</div>
      <div className="sk-ov-stats">
        {OVERVIEW.stats.map((s) => <div className="sk-ov-stat" key={s.k}><span className="sk-ov-v">{s.v}</span><span className="sk-ov-k">{s.k}</span></div>)}
      </div>
    </div>
  );
}
function StateLegend() {
  return (
    <div className="sk-legend">
      {Object.entries(STATES).map(([k, v]) => (
        <span className="sk-legend-item" key={k} data-state={k}><span className="sk-legend-hex" /><b>{v.zh}</b></span>
      ))}
      <span className="sk-legend-item" data-blind><span className="sk-legend-hex" /><b>高频盲区</b></span>
    </div>
  );
}

// ---------- 星座画布 ----------
function Constellation({ onPick, picked }) {
  const { nodes, edges, extent, depthMax } = useMemo(() => layoutRadial(TREE), []);
  const R = 30, PAD = 50;
  const VB = (extent + PAD) * 2;
  const C = VB / 2; // 中心
  const [zoom, setZoom] = useState(1);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const drag = useRef(null);
  const onDown = (e) => { drag.current = { sx: e.clientX, sy: e.clientY, px: pan.x, py: pan.y }; };
  const onMove = (e) => { if (drag.current) setPan({ x: drag.current.px + (e.clientX - drag.current.sx), y: drag.current.py + (e.clientY - drag.current.sy) }); };
  const onUp = () => { drag.current = null; };
  const px = (n) => C + n.x, py = (n) => C + n.y;

  return (
    <div className="sk-canvas">
      <div className="sk-zoom">
        <button onClick={() => setZoom((z) => Math.min(2, z + 0.2))}><LBIcon name="zoomIn" size={15} /></button>
        <button onClick={() => setZoom((z) => Math.max(0.5, z - 0.2))}><LBIcon name="zoomOut" size={15} /></button>
        <button onClick={() => { setZoom(1); setPan({ x: 0, y: 0 }); }} title="复位"><LBIcon name="target" size={15} /></button>
      </div>
      <svg className="sk-svg" viewBox={`0 0 ${VB} ${VB}`} preserveAspectRatio="xMidYMid meet"
        onMouseDown={onDown} onMouseMove={onMove} onMouseUp={onUp} onMouseLeave={onUp}
        style={{ cursor: drag.current ? "grabbing" : "grab" }}>
        <defs>
          <radialGradient id="skcore" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="rgba(110,139,255,.22)" /><stop offset="60%" stopColor="rgba(110,139,255,.05)" /><stop offset="100%" stopColor="rgba(110,139,255,0)" />
          </radialGradient>
          <filter id="skglow" x="-60%" y="-60%" width="220%" height="220%">
            <feGaussianBlur stdDeviation="3.2" result="b" /><feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>
        </defs>
        <g transform={`translate(${pan.x} ${pan.y}) scale(${zoom})`} style={{ transformOrigin: "center", transition: drag.current ? "none" : "transform .2s" }}>
          {/* 中心辉光 + 引导环 */}
          <circle cx={C} cy={C} r={extent * 0.9} fill="url(#skcore)" />
          {Array.from({ length: depthMax }).map((_, i) => (
            <circle key={i} cx={C} cy={C} r={(i + 1) * 116} fill="none" stroke="rgba(255,255,255,.05)" strokeDasharray="2 6" />
          ))}
          {/* 连线（能量流） */}
          {edges.map(({ from, to }, i) => {
            const x1 = px(from), y1 = py(from), x2 = px(to), y2 = py(to);
            const locked = stateOf(to) === "locked";
            const col = CATS[to.cat].color;
            return (
              <g key={i}>
                <line x1={x1} y1={y1} x2={x2} y2={y2} className="sk-edge" data-locked={locked || undefined}
                  stroke={locked ? "rgba(255,255,255,.07)" : col} strokeOpacity={locked ? 1 : .32} />
                {!locked && <line x1={x1} y1={y1} x2={x2} y2={y2} className="sk-edge-flow" stroke={col} />}
              </g>
            );
          })}
          {/* 节点 */}
          {nodes.map((n) => {
            const st = stateOf(n), blind = isBlind(n);
            const cx = px(n), cy = py(n), ccol = CATS[n.cat].color;
            const isRoot = n.depth === 0;
            const rr = isRoot ? R + 8 : R;
            const sel = picked && picked.id === n.id;
            return (
              <g key={n.id} className="sk-hex" data-state={st} data-blind={blind || undefined} data-root={isRoot || undefined} data-sel={sel || undefined}
                onClick={() => st !== "locked" && onPick(n)} style={{ cursor: st === "locked" ? "default" : "pointer", "--cat": ccol }}>
                {blind && <polygon className="sk-hex-pulse" points={hexPoints(cx, cy, rr + 6)} />}
                <polygon className="sk-hex-fill" points={hexPoints(cx, cy, rr)} filter={st !== "locked" ? "url(#skglow)" : undefined} />
                <polygon className="sk-hex-stroke" points={hexPoints(cx, cy, rr)} />
                {st === "locked"
                  ? <g className="sk-hex-lock" transform={`translate(${cx - 7} ${cy - 8})`}><LBIcon name="lock" size={14} /></g>
                  : <text x={cx} y={cy} className="sk-hex-label" textAnchor="middle" dominantBaseline="central" style={{ fontSize: isRoot ? 13 : (n.label.length > 4 ? 10 : 11.5) }}>{n.label}</text>}
                {st === "mastered" && !isRoot && <g className="sk-hex-badge" transform={`translate(${cx + rr - 12} ${cy - rr + 5})`}><LBIcon name="check" size={11} /></g>}
                {blind && <g className="sk-hex-badge blind" transform={`translate(${cx + rr - 13} ${cy - rr + 4})`}><LBIcon name="flame" size={12} /></g>}
              </g>
            );
          })}
        </g>
      </svg>
    </div>
  );
}

// ---------- 节点详情：含「遇到过的句子」 ----------
function NodeDetail({ node, onClose, onAct }) {
  if (!node) return null;
  const st = stateOf(node), blind = isBlind(node);
  const cat = CATS[node.cat];
  const sentences = [...(node.eg || [])].sort((a, b) => a.when - b.when); // 最新在上
  return (
    <div className="sk-detail-scrim" onClick={onClose}>
      <div className="sk-panel" onClick={(e) => e.stopPropagation()} style={{ "--cat": cat.color }}>
        <div className="sk-panel-head">
          <div>
            <span className="sk-panel-cat">{cat.zh}</span>
            <div className="sk-panel-label">{node.label}{blind && <span className="sk-panel-flame"><LBIcon name="flame" size={15} /></span>}</div>
          </div>
          <button className="sk-panel-close" onClick={onClose}><LBIcon name="close" size={16} /></button>
        </div>
        <div className="sk-panel-state" data-state={st}><span className="sk-panel-statedot" />{STATES[st].zh} · {STATES[st].desc}</div>
        <div className="sk-panel-metrics">
          <div className="sk-pm"><span className="sk-pm-v">{node.met}</span><span className="sk-pm-k">遇到次数</span></div>
          <div className="sk-pm"><span className="sk-pm-v">{Math.round(node.mastery * 100)}%</span><span className="sk-pm-k">掌握度</span></div>
        </div>
        <div className="sk-panel-bar"><span style={{ width: `${node.mastery * 100}%` }} /></div>

        {/* 遇到过的句子 */}
        <div className="sk-eg-head"><LBIcon name="book" size={13} /> 你遇到过的句子<span className="sk-eg-count">{sentences.length}</span></div>
        <div className="sk-eg-list">
          {sentences.length === 0 && <div className="sk-eg-empty">还没有记录到相关句子</div>}
          {sentences.map((s, i) => (
            <div className="sk-eg" key={i}>
              <span className="sk-eg-bar" />
              <div className="sk-eg-body">
                <div className="sk-eg-text" lang="en">{s.text}</div>
                <div className="sk-eg-meta"><span className="sk-eg-src">{s.src}</span> · {relTime(s.when)}</div>
              </div>
            </div>
          ))}
        </div>

        <div className="sk-panel-foot">
          <button className="sk-panel-btn" onClick={() => onAct({ node, action: "解析" })}><LBIcon name="book" size={14} /> 重新解析</button>
          <button className="sk-panel-btn primary" onClick={() => onAct({ node, action: "练习" })}><LBIcon name="spark" size={14} /> 举一反三</button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { OverviewHeader, StateLegend, Constellation, NodeDetail, layoutRadial });
