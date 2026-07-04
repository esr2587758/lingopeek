// cards.jsx — 「语法技能树」自上而下（层层递进）
// 纵向 tidy-tree：根在顶，向下逐层展开。深度 = 递进层级（根基→主干→分类→细节）。
// 复用 data.jsx 的三态 / 「懂了」掌握机制 / 盲区。
const { useState, useMemo, useRef } = React;

// 递进层级标签（左侧轴）
const LEVELS = ["根基", "两大支柱", "语法门类", "具体结构", "精细分支"];

// ---------- 纵向 tidy-tree 布局：叶子按序占列，父节点居中于子节点，零重叠 ----------
function layoutTree(nodes) {
  const byId = {}; nodes.forEach((n) => (byId[n.id] = { ...n, children: [] }));
  let root = null;
  nodes.forEach((n) => { if (n.parent) byId[n.parent].children.push(byId[n.id]); else root = byId[n.id]; });

  const XGAP = 78, YGAP = 132;
  let cursor = 0;
  // 后序：叶子顺序占列，内部节点居中于子节点范围
  const place = (node, depth) => {
    node.depth = depth;
    node.y = depth * YGAP;
    if (node.children.length === 0) {
      node.x = cursor * XGAP;
      cursor += 1;
    } else {
      node.children.forEach((c) => place(c, depth + 1));
      node.x = (node.children[0].x + node.children[node.children.length - 1].x) / 2;
    }
  };
  place(root, 0);

  const flat = Object.values(byId);
  const xs = flat.map((n) => n.x), ys = flat.map((n) => n.y);
  const minX = Math.min(...xs), maxX = Math.max(...xs);
  const maxY = Math.max(...ys);
  // 居中偏移到 0 起
  flat.forEach((n) => (n.x -= minX));
  const edges = [];
  flat.forEach((n) => n.children.forEach((c) => edges.push({ from: n, to: c })));
  return { nodes: flat, edges, width: maxX - minX, height: maxY, depthMax: Math.max(...flat.map((n) => n.depth)) };
}

function hexPoints(cx, cy, r) {
  const pts = [];
  for (let i = 0; i < 6; i++) {
    const a = (Math.PI / 180) * (60 * i - 30);
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

// ---------- 纵向树画布 ----------
function TreeCanvas({ onPick, picked }) {
  const { nodes, edges, width, height, depthMax } = useMemo(() => layoutTree(TREE), []);
  const R = 28, PADX = 60, PADY = 46;
  const VW = width + PADX * 2, VH = height + PADY * 2;
  const [zoom, setZoom] = useState(1);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const drag = useRef(null);
  const onDown = (e) => { drag.current = { sx: e.clientX, sy: e.clientY, px: pan.x, py: pan.y }; };
  const onMove = (e) => { if (drag.current) setPan({ x: drag.current.px + (e.clientX - drag.current.sx), y: drag.current.py + (e.clientY - drag.current.sy) }); };
  const onUp = () => { drag.current = null; };
  const px = (n) => PADX + n.x, py = (n) => PADY + n.y;

  // 平滑的自上而下连线（三次贝塞尔，垂直方向切线）
  const edgePath = (a, b) => {
    const x1 = px(a), y1 = py(a) + R, x2 = px(b), y2 = py(b) - R;
    const my = (y1 + y2) / 2;
    return `M ${x1} ${y1} C ${x1} ${my}, ${x2} ${my}, ${x2} ${y2}`;
  };

  return (
    <div className="sk-canvas">
      {/* 左侧递进层级轴（跟随缩放与竖向平移） */}
      <div className="sk-levels">
        {LEVELS.slice(0, depthMax + 1).map((lv, i) => (
          <div className="sk-level" key={i} style={{ top: `${(PADY + i * 132) * zoom + pan.y}px` }}>
            <span className="sk-level-n">L{i}</span><span className="sk-level-t">{lv}</span>
          </div>
        ))}
        <div className="sk-levels-arrow"><LBIcon name="arrowDown" size={16} /><span>由浅入深</span></div>
      </div>

      <div className="sk-zoom">
        <button onClick={() => setZoom((z) => Math.min(2, z + 0.15))}><LBIcon name="zoomIn" size={15} /></button>
        <button onClick={() => setZoom((z) => Math.max(0.4, z - 0.15))}><LBIcon name="zoomOut" size={15} /></button>
        <button onClick={() => { setZoom(1); setPan({ x: 0, y: 0 }); }} title="复位"><LBIcon name="target" size={15} /></button>
      </div>

      <svg className="sk-svg" width={VW * zoom} height={VH * zoom} viewBox={`0 0 ${VW} ${VH}`}
        onMouseDown={onDown} onMouseMove={onMove} onMouseUp={onUp} onMouseLeave={onUp}
        style={{ cursor: drag.current ? "grabbing" : "grab" }}>
        <defs>
          <filter id="skglow" x="-60%" y="-60%" width="220%" height="220%">
            <feGaussianBlur stdDeviation="3" result="b" /><feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>
          <linearGradient id="sklevel" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="rgba(110,139,255,.05)" /><stop offset="100%" stopColor="rgba(110,139,255,0)" />
          </linearGradient>
        </defs>
        <g transform={`translate(${pan.x} ${pan.y})`} style={{ transition: drag.current ? "none" : "transform .2s" }}>
          {/* 层级分隔横线 */}
          {Array.from({ length: depthMax + 1 }).map((_, i) => (
            <line key={i} x1={0} y1={PADY + i * 132} x2={VW} y2={PADY + i * 132} stroke="rgba(255,255,255,.04)" strokeDasharray="1 8" />
          ))}
          {/* 连线（能量流） */}
          {edges.map(({ from, to }, i) => {
            const locked = stateOf(to) === "locked";
            const col = CATS[to.cat].color;
            return (
              <g key={i}>
                <path d={edgePath(from, to)} className="sk-edge" data-locked={locked || undefined} fill="none"
                  stroke={locked ? "rgba(255,255,255,.08)" : col} strokeOpacity={locked ? 1 : .34} />
                {!locked && <path d={edgePath(from, to)} className="sk-edge-flow" fill="none" stroke={col} />}
              </g>
            );
          })}
          {/* 节点 */}
          {nodes.map((n) => {
            const st = stateOf(n), blind = isBlind(n);
            const cx = px(n), cy = py(n), ccol = CATS[n.cat].color;
            const isRoot = n.depth === 0;
            const rr = isRoot ? R + 7 : R;
            const sel = picked && picked.id === n.id;
            return (
              <g key={n.id} className="sk-hex" data-state={st} data-blind={blind || undefined} data-root={isRoot || undefined} data-sel={sel || undefined}
                onClick={() => st !== "locked" && onPick(n)} style={{ cursor: st === "locked" ? "default" : "pointer", "--cat": ccol }}>
                {blind && <polygon className="sk-hex-pulse" points={hexPoints(cx, cy, rr + 6)} />}
                <polygon className="sk-hex-fill" points={hexPoints(cx, cy, rr)} filter={st !== "locked" ? "url(#skglow)" : undefined} />
                <polygon className="sk-hex-stroke" points={hexPoints(cx, cy, rr)} />
                {st === "locked"
                  ? <g className="sk-hex-lock" transform={`translate(${cx - 7} ${cy - 8})`}><LBIcon name="lock" size={14} /></g>
                  : <text x={cx} y={cy} className="sk-hex-label" textAnchor="middle" dominantBaseline="central" style={{ fontSize: isRoot ? 13 : (n.label.length > 4 ? 9.5 : 11) }}>{n.label}</text>}
                {st === "mastered" && !isRoot && <g className="sk-hex-badge" transform={`translate(${cx + rr - 11} ${cy - rr + 4})`}><LBIcon name="check" size={11} /></g>}
                {blind && <g className="sk-hex-badge blind" transform={`translate(${cx + rr - 12} ${cy - rr + 3})`}><LBIcon name="flame" size={12} /></g>}
              </g>
            );
          })}
        </g>
      </svg>
    </div>
  );
}

// ---------- 节点详情：含「遇到过的句子」+「懂了」确认 ----------
function NodeDetail({ node, onClose, onAct, onConfirm }) {
  if (!node) return null;
  const st = stateOf(node), blind = isBlind(node), nudge = shouldNudge(node);
  const cat = CATS[node.cat];
  const u = liveUnderstood(node);
  const mastery = masteryFrom(u);
  const sentences = (node.eg || []).map((s, i) => ({ ...s, _i: i })).sort((a, b) => a.when - b.when);

  return (
    <div className="sk-panel" style={{ "--cat": cat.color }}>
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
        <div className="sk-pm"><span className="sk-pm-v">{Math.round(mastery * 100)}%</span><span className="sk-pm-k">掌握度</span></div>
      </div>
      <div className="sk-panel-bar">
        <span style={{ width: `${mastery * 100}%` }} />
        <i className="sk-panel-bar-thr" style={{ left: `${masteryFrom(MASTER_THRESHOLD) * 100}%` }} />
      </div>
      <div className="sk-panel-why">
        {u === 0
          ? "你还没在任何句子里确认「懂了」"
          : <>你已在 <b>{u}</b> 个句子里确认看懂{st !== "mastered" && <>，再确认 {MASTER_THRESHOLD - u} 次即「已掌握」</>}</>}
      </div>

      {nudge && (
        <div className="sk-nudge">
          <LBIcon name="spark" size={14} />
          <span>这个你最近遇到 {node.met} 次都没再查，已经看得懂了吗？</span>
          <button onClick={() => onConfirm(node, "nudge")}>标记已掌握</button>
        </div>
      )}

      <div className="sk-eg-head"><LBIcon name="book" size={13} /> 你遇到过的句子<span className="sk-eg-count">{sentences.length}</span></div>
      <div className="sk-eg-list">
        {sentences.length === 0 && <div className="sk-eg-empty">还没有记录到相关句子</div>}
        {sentences.map((s) => {
          const ok = node.confirms && node.confirms[s._i];
          return (
            <div className="sk-eg" key={s._i} data-ok={ok || undefined}>
              <span className="sk-eg-bar" />
              <div className="sk-eg-body">
                <div className="sk-eg-text" lang="en">{s.text}</div>
                <div className="sk-eg-meta"><span className="sk-eg-src">{s.src}</span> · {relTime(s.when)}</div>
              </div>
              <button className="sk-eg-got" data-ok={ok || undefined} title={ok ? "已标记看懂，点击取消" : "标记这句看懂了"}
                onClick={() => onConfirm(node, s._i)}>
                <LBIcon name="check" size={13} /> {ok ? "懂了" : "懂了？"}
              </button>
            </div>
          );
        })}
      </div>

      <div className="sk-panel-foot">
        <button className="sk-panel-btn" onClick={() => onAct({ node, action: "解析" })}><LBIcon name="book" size={14} /> 重新解析</button>
        <button className="sk-panel-btn primary" onClick={() => onAct({ node, action: "练习" })}><LBIcon name="spark" size={14} /> 举一反三</button>
      </div>
    </div>
  );
}

Object.assign(window, { OverviewHeader, StateLegend, TreeCanvas, NodeDetail, layoutTree });
