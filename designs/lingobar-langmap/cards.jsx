// cards.jsx — 「我的语言地图」组件：画像头 / 三形态地图 / 洞察条 / 成长轨迹
const { useState, useMemo } = React;

// 节点半径：遇到次数 → 16–46
function radiusOf(n) { return 16 + (n.met / MAX_MET) * 30; }

// ---------- 顶部一句话画像 ----------
function PortraitHeader() {
  return (
    <div className="lm-portrait">
      <div className="lm-portrait-line">
        <span className="lm-portrait-icon"><LBIcon name="eye" size={18} /></span>
        {PORTRAIT.line}
      </div>
      <div className="lm-stats">
        {PORTRAIT.stats.map((s) => (
          <div className="lm-stat" key={s.k}>
            <span className="lm-stat-v">{s.v}<i>{s.suffix}</i></span>
            <span className="lm-stat-k">{s.k}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ---------- gap 图例（三形态共用） ----------
function GapLegend() {
  return (
    <div className="lm-legend">
      {Object.entries(LEVELS).map(([k, v]) => (
        <span className="lm-legend-item" key={k}>
          <span className="lm-legend-dot" style={{ background: v.color }} />
          <b>{v.zh}</b><span className="lm-legend-desc">{v.desc}</span>
        </span>
      ))}
      <span className="lm-legend-hint">圈越大 = 遇到越多 · 颜色 = 暴露与掌握的差距</span>
    </div>
  );
}

// ====== 形态一：星系/气泡（力导向，确定性碰撞布局） ======
function GalaxyMap({ onPick }) {
  const W = 560, H = 360;
  // 按 gap 排序：盲区大圈先放中心，已掌握小圈靠外。螺旋 + 碰撞回避。
  const placed = useMemo(() => {
    const order = [...NODES].sort((a, b) => gapOf(b) - gapOf(a));
    const out = [];
    const cx = W / 2, cy = H / 2;
    for (const n of order) {
      const r = radiusOf(n);
      let best = null;
      for (let t = 0; t < 600; t++) {
        const ang = t * 0.5;
        const rad = 6 + t * 0.9;
        const x = cx + Math.cos(ang) * rad * 1.35;
        const y = cy + Math.sin(ang) * rad;
        if (x - r < 6 || x + r > W - 6 || y - r < 6 || y + r > H - 6) continue;
        let ok = true;
        for (const p of out) {
          const dx = x - p.x, dy = y - p.y;
          if (Math.hypot(dx, dy) < r + p.r + 5) { ok = false; break; }
        }
        if (ok) { best = { x, y }; break; }
      }
      if (!best) best = { x: cx, y: cy };
      out.push({ n, r, x: best.x, y: best.y });
    }
    return out;
  }, []);

  return (
    <div className="lm-galaxy">
      <svg viewBox={`0 0 ${W} ${H}`} className="lm-galaxy-svg" preserveAspectRatio="xMidYMid meet">
        <defs>
          <radialGradient id="lmcore" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="rgba(110,139,255,.18)" />
            <stop offset="100%" stopColor="rgba(110,139,255,0)" />
          </radialGradient>
        </defs>
        <ellipse cx={W/2} cy={H/2} rx={W/2.4} ry={H/2.6} fill="url(#lmcore)" />
        {placed.map(({ n, r, x, y }) => {
          const col = gapColor(n);
          const blind = levelOf(n) === "blind";
          return (
            <g key={n.id} className="lm-node" onClick={() => onPick(n)} style={{ cursor: "pointer" }}>
              {blind && <circle cx={x} cy={y} r={r + 5} fill="none" stroke={col} strokeOpacity=".35" className="lm-pulse" />}
              <circle cx={x} cy={y} r={r} fill={col} fillOpacity={blind ? .92 : .5} stroke={col} strokeOpacity=".9" />
              <text x={x} y={y} className="lm-node-label" textAnchor="middle" dominantBaseline="central"
                style={{ fontSize: Math.max(9, Math.min(13, r / 2.6)) }}>{n.label}</text>
              <text x={x} y={y + r - 6} className="lm-node-met" textAnchor="middle">{n.met}</text>
            </g>
          );
        })}
      </svg>
    </div>
  );
}

// ====== 形态二：体系板块图（按 category 分区 + 每区覆盖率） ======
function SystemMap({ onPick }) {
  const groups = useMemo(() => {
    return Object.entries(CATEGORIES).map(([cat, meta]) => {
      const items = NODES.filter((n) => n.cat === cat).sort((a, b) => gapOf(b) - gapOf(a));
      const mastered = items.filter((n) => levelOf(n) === "solid").length;
      return { cat, meta, items, mastered };
    }).filter((g) => g.items.length > 0);
  }, []);
  return (
    <div className="lm-system">
      {groups.map((g) => (
        <div className="lm-sys-block" key={g.cat} style={{ "--cat": g.meta.color }}>
          <div className="lm-sys-head">
            <span className="lm-sys-name">{g.meta.zh}</span>
            <span className="lm-sys-cov">{g.mastered}/{g.items.length} 掌握</span>
          </div>
          <div className="lm-sys-bar"><span style={{ width: `${(g.mastered / g.items.length) * 100}%` }} /></div>
          <div className="lm-sys-items">
            {g.items.map((n) => (
              <button key={n.id} className="lm-chip" data-level={levelOf(n)} onClick={() => onPick(n)}
                style={{ "--gap": gapColor(n) }}>
                <span className="lm-chip-dot" />
                <span className="lm-chip-label">{n.label}</span>
                <span className="lm-chip-met">{n.met}</span>
              </button>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

// ====== 形态三：分组卡片墙（盲区/巩固/已掌握） ======
function CardWall({ onPick }) {
  const cols = useMemo(() => {
    const by = { blind: [], firming: [], solid: [] };
    [...NODES].sort((a, b) => gapOf(b) - gapOf(a)).forEach((n) => by[levelOf(n)].push(n));
    return by;
  }, []);
  return (
    <div className="lm-wall">
      {["blind", "firming", "solid"].map((lv) => (
        <div className="lm-wall-col" key={lv}>
          <div className="lm-wall-head" style={{ "--lv": LEVELS[lv].color }}>
            <span className="lm-wall-dot" />
            <span className="lm-wall-title">{LEVELS[lv].zh}</span>
            <span className="lm-wall-count">{cols[lv].length}</span>
          </div>
          <div className="lm-wall-list">
            {cols[lv].map((n) => (
              <button key={n.id} className="lm-wallcard" onClick={() => onPick(n)} style={{ "--gap": gapColor(n) }}>
                <div className="lm-wallcard-top">
                  <span className="lm-wallcard-label">{n.label}</span>
                  <span className="lm-wallcard-cat">{CATEGORIES[n.cat].zh}</span>
                </div>
                <div className="lm-wallcard-bars">
                  <div className="lm-mini"><span className="lm-mini-k">遇到</span><span className="lm-mini-track"><i style={{ width: `${(n.met / MAX_MET) * 100}%`, background: "var(--gap)" }} /></span><span className="lm-mini-v">{n.met}</span></div>
                  <div className="lm-mini"><span className="lm-mini-k">掌握</span><span className="lm-mini-track"><i style={{ width: `${n.mastery * 100}%`, background: "#5bbf8a" }} /></span><span className="lm-mini-v">{Math.round(n.mastery * 100)}%</span></div>
                </div>
              </button>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

// ---------- 洞察条 ----------
function InsightBar({ onAct }) {
  return (
    <div className="lm-insights">
      <div className="lm-insights-head"><LBIcon name="spark" size={15} /> 给你的提示</div>
      {INSIGHTS.map((it) => (
        <div className="lm-insight" key={it.id} data-tone={it.tone}>
          <span className="lm-insight-ic"><LBIcon name={it.tone === "good" ? "check" : "alert"} size={14} /></span>
          <span className="lm-insight-text">{it.text}</span>
          <button className="lm-insight-act" onClick={() => onAct(it)}>{it.action} <LBIcon name="arrowRight" size={13} /></button>
        </div>
      ))}
    </div>
  );
}

// ---------- 成长轨迹 ----------
function GrowthTrail() {
  return (
    <div className="lm-trail">
      <div className="lm-trail-head"><LBIcon name="trend" size={15} /> 障碍在变浅</div>
      <div className="lm-trail-list">
        {TRAIL.map((t) => {
          const done = t.to >= 0.75;
          return (
            <div className="lm-trailrow" key={t.id}>
              <span className="lm-trail-label">{t.label}</span>
              <span className="lm-trail-track">
                <i className="lm-trail-from" style={{ left: `${t.from * 100}%` }} />
                <i className="lm-trail-fill" style={{ left: `${t.from * 100}%`, width: `${(t.to - t.from) * 100}%` }} data-done={done || undefined} />
                <i className="lm-trail-to" style={{ left: `${t.to * 100}%` }} data-done={done || undefined} />
              </span>
              <span className="lm-trail-note" data-done={done || undefined}>{done ? "✓ " : ""}{t.note}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ---------- 节点详情弹层 ----------
function NodeDetail({ node, onClose, onAct }) {
  if (!node) return null;
  const lv = levelOf(node);
  return (
    <div className="lm-detail-scrim" onClick={onClose}>
      <div className="lm-detail" onClick={(e) => e.stopPropagation()} style={{ "--gap": gapColor(node) }}>
        <div className="lm-detail-head">
          <span className="lm-detail-cat" style={{ color: CATEGORIES[node.cat].color }}>{CATEGORIES[node.cat].zh}</span>
          <button className="lm-detail-close" onClick={onClose}><LBIcon name="close" size={15} /></button>
        </div>
        <div className="lm-detail-label">{node.label}</div>
        <div className="lm-detail-level" data-level={lv}><span className="lm-detail-leveldot" />{LEVELS[lv].zh}·{LEVELS[lv].desc}</div>
        <div className="lm-detail-metrics">
          <div className="lm-dmetric"><span className="lm-dmetric-v">{node.met}</span><span className="lm-dmetric-k">遇到次数</span></div>
          <div className="lm-dmetric"><span className="lm-dmetric-v">{Math.round(node.mastery * 100)}%</span><span className="lm-dmetric-k">掌握度</span></div>
          <div className="lm-dmetric"><span className="lm-dmetric-v">{node.streak}</span><span className="lm-dmetric-k">连续没查</span></div>
        </div>
        <div className="lm-detail-meta">主要来自 <b>{node.srcTop}</b> · 首次遇到约 {node.since} 天前</div>
        <div className="lm-detail-foot">
          <button className="lm-detail-btn" onClick={() => onAct({ target: node.id, action: "解析" })}><LBIcon name="book" size={14} /> 重新解析</button>
          <button className="lm-detail-btn primary" onClick={() => onAct({ target: node.id, action: "练习" })}><LBIcon name="spark" size={14} /> 举一反三</button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  PortraitHeader, GapLegend, GalaxyMap, SystemMap, CardWall,
  InsightBar, GrowthTrail, NodeDetail, radiusOf,
});
