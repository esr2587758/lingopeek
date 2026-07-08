// cards.jsx — 「语法星座」放射状布局 + 六边形 + 例句详情
const { useState, useMemo, useRef } = React;

// ---------- 双半球放射布局：根居中，词法占左 180°、句法占右 180°，各 50% ----------
// 两大支柱各分一个半圆，无论节点多少都严格对半；支柱在半圆外缘作弧形标签。
const BASE_R = 19; // 六边形基准半径
// 大小按遇到频次：高频节点更大 —— 让高频盲区又大又红，自然抓住注意力（幅度克制，避免密侧相撞）
function sizeOf(n) {
  if (n.depth === 0) return 32;      // 根
  if (n.pillar) return 27;           // 支柱枢纽
  const t = Math.min(1, (n.met || 0) / 40); // 0..1
  return BASE_R * (0.72 + 0.34 * t); // ~14..19
}
// 纯放射树（dendrogram）：每片叶子在半球内占等宽角度槽，父节点居中于子节点——
// 天然零重叠、零缠绕，不再做碰撞松弛（松弛正是之前结块的元凶）。
function layoutRadial(nodes) {
  const byId = {}; nodes.forEach((n) => (byId[n.id] = { ...n, children: [] }));
  let root = null;
  nodes.forEach((n) => { if (n.parent) byId[n.parent].children.push(byId[n.id]); else root = byId[n.id]; });

  // 两大支柱：morph=左半球, syntax=右半球
  const pillars = root.children.map((c) => byId[c.id]).filter((c) => c.pillar);

  // 各深度半径（同心环）——外环拉大间距，缓解密侧（词法34叶）拥挤
  const RING = [0, 122, 292, 428, 560];
  const radiusAt = (d) => RING[d] != null ? RING[d] : RING[RING.length - 1] + (d - RING.length + 1) * 100;

  // 坐标映射 x=cos(angle-PI/2): angle=PI/2→右, 3PI/2→左。
  // 左半球(词法, x<0): [PI, 2PI], 中线 3PI/2=正左；右半球(句法, x>0): [0, PI], 中线 PI/2=正右。
  const G = 0.16; // 中线两侧留白
  const HEMI = { morph: [Math.PI + G, Math.PI * 2 - G], syntax: [G, Math.PI - G] };

  root.depth = 0; root.angle = 0; root.radius = 0;

  // 每个半球：按 DFS 顺序给叶子等宽角度槽；内部节点角度 = 子节点角度范围的中点
  let slot;
  const place = (node, depth, span) => {
    node.depth = depth;
    node.radius = radiusAt(depth);
    if (node.children.length === 0) {
      node.angle = span[0] + (slot + 0.5) * span[2];
      slot += 1;
    } else {
      node.children.forEach((c) => place(c, depth + 1, span));
      node.angle = (node.children[0].angle + node.children[node.children.length - 1].angle) / 2;
    }
  };

  const countLeaves = (node) => node.children.length === 0 ? 1 : node.children.reduce((s, c) => s + countLeaves(c), 0);

  pillars.forEach((p) => {
    const [a0, a1] = HEMI[p.id];
    const nLeaves = countLeaves(p);
    const step = (a1 - a0) / nLeaves;
    slot = 0;
    // 支柱本体：深度 1，落在半球中线内侧
    p.depth = 1; p.radius = radiusAt(1); p._pillar = p.id;
    // 门类从深度 2 起铺开
    p.children.forEach((c) => { const mark = (nd) => { nd._pillar = p.id; nd.children.forEach(mark); }; mark(c); });
    p.children.forEach((c) => place(c, 2, [a0, a1, step]));
    // 支柱角度 = 其门类角度范围中点（贴合半球中线）
    p.angle = (p.children[0].angle + p.children[p.children.length - 1].angle) / 2;
  });

  const flat = Object.values(byId);
  flat.forEach((n) => {
    n.x = Math.cos(n.angle - Math.PI / 2) * n.radius;
    n.y = Math.sin(n.angle - Math.PI / 2) * n.radius;
    n._r = sizeOf(n);
  });

  // 半球标签
  const sectors = pillars.map((p) => {
    const [a0, a1] = HEMI[p.id];
    return { id: p.id, label: p.label, cat: p.cat, a0, a1, side: p.id === "morph" ? "L" : "R" };
  });

  const maxR = Math.max(...flat.map((n) => Math.hypot(n.x, n.y) + n._r));
  const edges = [];
  flat.forEach((n) => n.children.forEach((c) => edges.push({ from: n, to: c })));
  return { nodes: flat, edges, extent: maxR, depthMax: Math.max(...flat.map(n => n.depth)), sectors };
}

function hexPoints(cx, cy, r) {
  const pts = [];
  for (let i = 0; i < 6; i++) {
    const a = (Math.PI / 180) * (60 * i - 30); // pointy-top
    pts.push(`${(cx + r * Math.cos(a)).toFixed(1)},${(cy + r * Math.sin(a)).toFixed(1)}`);
  }
  return pts.join(" ");
}

// 放射式连线：先沿父角度向外走到中间半径，再平滑摆到子角度——形成柔和的放射曲线
function radialLink(from, to, C) {
  const pt = (ang, rad) => [C + Math.cos(ang - Math.PI / 2) * rad, C + Math.sin(ang - Math.PI / 2) * rad];
  const rMid = (from.radius + to.radius) / 2;
  const [x1, y1] = pt(from.angle, from.radius);
  const [cx1, cy1] = pt(from.angle, rMid); // 控制点1：父角度、中间半径
  const [cx2, cy2] = pt(to.angle, rMid);   // 控制点2：子角度、中间半径
  const [x2, y2] = pt(to.angle, to.radius);
  return `M ${x1.toFixed(1)} ${y1.toFixed(1)} C ${cx1.toFixed(1)} ${cy1.toFixed(1)}, ${cx2.toFixed(1)} ${cy2.toFixed(1)}, ${x2.toFixed(1)} ${y2.toFixed(1)}`;
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
  const { nodes, edges, extent, depthMax, sectors } = useMemo(() => layoutRadial(TREE), []);
  const R = 30, PAD = 54;
  const RING_R = [0, 122, 292, 428, 560];
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
          {/* 左右半球底色（词法 | 句法 各 50%） */}
          {sectors.map((s) => {
            const col = CATS[s.cat].color;
            const left = s.side === "L";
            return (
              <rect key={s.id} x={left ? 0 : C} y={0} width={C} height={VB}
                fill={col} fillOpacity={0.045} />
            );
          })}
          {/* 中线分隔（词法 / 句法 分界） */}
          <line x1={C} y1={PAD * 0.4} x2={C} y2={VB - PAD * 0.4} stroke="rgba(255,255,255,.14)" strokeDasharray="2 8" />
          {/* 半球标题 */}
          {sectors.map((s) => {
            const col = CATS[s.cat].color;
            const left = s.side === "L";
            return (
              <text key={s.id} x={left ? C - 24 : C + 24} y={PAD * 0.75} textAnchor={left ? "end" : "start"}
                className="sk-hemi-label" style={{ fill: col }}>{s.label}</text>
            );
          })}
          {/* 中心辉光 + 引导环 */}
          <circle cx={C} cy={C} r={extent * 0.85} fill="url(#skcore)" />
          {RING_R.slice(1).map((r, i) => (
            <circle key={i} cx={C} cy={C} r={r} fill="none" stroke="rgba(255,255,255,.05)" strokeDasharray="2 6" />
          ))}
          {/* 连线（放射曲线：沿半径外扩、角度平滑过渡，dendrogram 风格） */}
          {edges.map(({ from, to }, i) => {
            const locked = stateOf(to) === "locked";
            const col = CATS[to.cat].color;
            const d = radialLink(from, to, C);
            return (
              <g key={i}>
                <path d={d} className="sk-edge" data-locked={locked || undefined} fill="none"
                  stroke={locked ? "rgba(255,255,255,.07)" : col} strokeOpacity={locked ? 1 : .32} />
                {!locked && <path d={d} className="sk-edge-flow" fill="none" stroke={col} />}
              </g>
            );
          })}
          {/* 节点（大小按遇到频次 n._r） */}
          {nodes.map((n) => {
            const st = stateOf(n), blind = isBlind(n);
            const cx = px(n), cy = py(n), ccol = CATS[n.cat].color;
            const isRoot = n.depth === 0, isPillar = n.pillar;
            const rr = n._r;
            const sel = picked && picked.id === n.id;
            const fs = isRoot ? 13 : isPillar ? 13 : (rr < 20 ? 8.5 : n.label.length > 4 ? 9.5 : 11);
            return (
              <g key={n.id} className="sk-hex" data-state={st} data-blind={blind || undefined} data-root={isRoot || undefined} data-pillar={isPillar || undefined} data-sel={sel || undefined}
                onClick={() => st !== "locked" && onPick(n)} style={{ cursor: st === "locked" ? "default" : "pointer", "--cat": ccol }}>
                {blind && <polygon className="sk-hex-pulse" points={hexPoints(cx, cy, rr + 6)} />}
                <polygon className="sk-hex-fill" points={hexPoints(cx, cy, rr)} filter={st !== "locked" ? "url(#skglow)" : undefined} />
                <polygon className="sk-hex-stroke" points={hexPoints(cx, cy, rr)} />
                {st === "locked"
                  ? <g className="sk-hex-lock" transform={`translate(${cx - 7} ${cy - 8})`}><LBIcon name="lock" size={14} /></g>
                  : <text x={cx} y={cy} className="sk-hex-label" textAnchor="middle" dominantBaseline="central" style={{ fontSize: fs }}>{n.label}</text>}
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

// ---------- 节点详情：含「遇到过的句子」+「懂了」确认 ----------
function NodeDetail({ node, onClose, onAct, onConfirm }) {
  if (!node) return null;
  const st = stateOf(node), blind = isBlind(node), nudge = shouldNudge(node);
  const cat = CATS[node.cat];
  const u = liveUnderstood(node);
  const mastery = masteryFrom(u);
  // 句子按时间倒序（最新在上），但保留原始索引以便切换 confirms
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
        {/* 阈值刻度：到达即已掌握 */}
        <i className="sk-panel-bar-thr" style={{ left: `${masteryFrom(MASTER_THRESHOLD) * 100}%` }} />
      </div>
      {/* 掌握度可解释来源 */}
      <div className="sk-panel-why">
        {u === 0
          ? "你还没在任何句子里确认「懂了」"
          : <>你已在 <b>{u}</b> 个句子里确认看懂{st !== "mastered" && <>，再确认 {MASTER_THRESHOLD - u} 次即「已掌握」</>}</>}
      </div>

      {/* 轻推断兜底提示 */}
      {nudge && (
        <div className="sk-nudge">
          <LBIcon name="spark" size={14} />
          <span>这个你最近遇到 {node.met} 次都没再查，已经看得懂了吗？</span>
          <button onClick={() => onConfirm(node, "nudge")}>标记已掌握</button>
        </div>
      )}

      {/* 遇到过的句子（每句可点「懂了」） */}
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

Object.assign(window, { OverviewHeader, StateLegend, Constellation, NodeDetail, layoutRadial });
