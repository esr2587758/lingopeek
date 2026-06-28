// cards.jsx — 条目卡 / 详情抽屉 / 类型标签 / 设置控件（收藏与历史共用）
const { useState } = React;

// 句型占位符 {…} 高亮
function renderPattern(text) {
  const parts = String(text).split(/(\{[^}]*\})/g);
  return parts.map((p, i) =>
    /^\{.*\}$/.test(p)
      ? <span key={i} className="hub-slot">{p.slice(1, -1)}</span>
      : <span key={i}>{p}</span>
  );
}

function TypeTag({ type }) {
  const hue = TYPE_HUES[type] || "#6e8bff";
  return <span className="hub-typetag" style={{ "--hue": hue }}>{type}</span>;
}

function ActionBadge({ action }) {
  return <span className="hub-actbadge">{action}</span>;
}

// 通用条目卡（收藏 / 历史 共用；mode 决定附加元素）
function ItemCard({ item, mode, selected, onOpen, onCopy, onPlay, onRelaunch, onSave, onDelete }) {
  const isPattern = item.type === "句型";
  const sound = item.type === "短语" || item.type === "英文" || item.type === "例句";
  return (
    <div className="hub-card" data-selected={selected || undefined} onClick={() => onOpen(item)}>
      <div className="hub-card-top">
        <TypeTag type={item.type} />
        {mode === "history" && <ActionBadge action={item.action} />}
        {mode === "history" && item.status === "saved" && (
          <span className="hub-savedmark" title="已收藏"><LBIcon name="starFill" size={12} /></span>
        )}
        <span className="hub-card-time">{relTime(item.when)}</span>
      </div>
      <div className={"hub-card-text" + (isPattern ? " is-pattern" : "")} lang="en">
        {isPattern ? renderPattern(item.text) : item.text}
      </div>
      {item.ipa && <div className="hub-card-ipa" lang="en">{item.ipa}</div>}
      {item.meta && <div className="hub-card-meta">{item.meta}</div>}
      <div className="hub-card-foot">
        <span className="hub-card-src"><LBIcon name="bookmark" size={11} /> {item.src}</span>
        <div className="hub-card-acts" onClick={(e) => e.stopPropagation()}>
          {sound && <button className="hub-iconbtn" title="发音" onClick={() => onPlay(item)}><LBIcon name="sound" size={14} /></button>}
          <button className="hub-iconbtn" title="复制" onClick={() => onCopy(item)}><LBIcon name="copy" size={14} /></button>
          {mode === "history" && item.status !== "saved" && (
            <button className="hub-iconbtn save" title="转存到收藏" onClick={() => onSave(item)}><LBIcon name="star" size={14} /></button>
          )}
          <button className="hub-iconbtn" title="重新解析" onClick={() => onRelaunch(item)}><LBIcon name="refresh" size={14} /></button>
          {mode === "collection" && (
            <button className="hub-iconbtn danger" title="删除" onClick={() => onDelete(item)}><LBIcon name="trash" size={14} /></button>
          )}
        </div>
      </div>
    </div>
  );
}

// 详情抽屉
function ItemDetail({ item, mode, onClose, onCopy, onPlay, onRelaunch, onSave, onDelete }) {
  if (!item) {
    return (
      <div className="hub-detail empty">
        <div className="hub-detail-empty">
          <LBIcon name="bookmark" size={26} />
          <p>选择左侧条目查看详情</p>
        </div>
      </div>
    );
  }
  const isPattern = item.type === "句型";
  return (
    <div className="hub-detail">
      <div className="hub-detail-head">
        <div className="hub-detail-tags">
          <TypeTag type={item.type} />
          {mode === "history" && <ActionBadge action={item.action} />}
        </div>
        <button className="hub-iconbtn" onClick={onClose}><LBIcon name="close" size={15} /></button>
      </div>
      <div className="hub-detail-body">
        <div className={"hub-detail-text" + (isPattern ? " is-pattern" : "")} lang="en">
          {isPattern ? renderPattern(item.text) : item.text}
        </div>
        {item.ipa && <div className="hub-detail-ipa" lang="en">{item.ipa}</div>}
        {item.meta && (
          <div className="hub-detail-row"><span className="hub-detail-lbl">释义 / 说明</span><div className="hub-detail-val">{item.meta}</div></div>
        )}
        {item.colloc && item.colloc.length > 0 && (
          <div className="hub-detail-row"><span className="hub-detail-lbl">关键搭配</span>
            <div className="hub-detail-collocs">{item.colloc.map((c, i) => <span key={i} className="hub-colloc" lang="en">{c}</span>)}</div>
          </div>
        )}
        <div className="hub-detail-row">
          <span className="hub-detail-lbl">来源</span>
          <div className="hub-detail-val"><LBIcon name="bookmark" size={12} /> {item.src} · {relTime(item.when)}</div>
        </div>
      </div>
      <div className="hub-detail-foot">
        <button className="hub-foot-btn" onClick={() => onCopy(item)}><LBIcon name="copy" size={14} /> 复制</button>
        {mode === "history" && item.status !== "saved" && (
          <button className="hub-foot-btn" onClick={() => onSave(item)}><LBIcon name="star" size={14} /> 转存收藏</button>
        )}
        {mode === "collection" && (
          <button className="hub-foot-btn danger" onClick={() => onDelete(item)}><LBIcon name="trash" size={14} /> 删除</button>
        )}
        <div className="hub-foot-spacer" />
        <button className="hub-foot-btn primary" onClick={() => onRelaunch(item)}><LBIcon name="refresh" size={14} /> 重新解析</button>
      </div>
    </div>
  );
}

// ---- 设置控件（复用 settings 风格） ----
function Toggle({ on, onChange }) {
  return <button className="hub-toggle" data-on={on || undefined} onClick={() => onChange(!on)}><span className="hub-toggle-knob" /></button>;
}
function Segmented({ options, value, onChange }) {
  return (
    <div className="hub-seg">
      {options.map((o) => <button key={o} className="hub-seg-opt" data-on={value === o || undefined} onClick={() => onChange(o)}>{o}</button>)}
    </div>
  );
}
function Select({ options, value, onChange }) {
  return (
    <div className="hub-select">
      <select value={value} onChange={(e) => onChange(e.target.value)}>
        {options.map((o) => <option key={o} value={o}>{o}</option>)}
      </select>
      <span className="hub-select-caret"><LBIcon name="chevronDown" size={14} /></span>
    </div>
  );
}
function SettingRow({ title, desc, children, required }) {
  return (
    <div className="hub-set-row">
      <div className="hub-set-label">
        <div className="hub-set-title">{title}{required && <span className="hub-req-dot" />}</div>
        {desc && <div className="hub-set-desc">{desc}</div>}
      </div>
      <div className="hub-set-ctrl">{children}</div>
    </div>
  );
}
function Badge({ kind, children }) { return <span className="hub-badge" data-kind={kind}>{children}</span>; }
function GateBanner({ text }) {
  return <div className="hub-gatebanner"><LBIcon name="alert" size={15} /><span>{text}</span></div>;
}
function Hotkey({ keys }) {
  return <div className="hub-hotkey">{keys.map((k, i) => <kbd key={i}>{k}</kbd>)}</div>;
}
function SchemeGrid({ value, onChange }) {
  return (
    <div className="hub-scheme-grid">
      {APPEARANCE_SCHEMES.map((s) => (
        <button key={s.id} className="hub-scheme" data-on={value === s.id || undefined} onClick={() => onChange(s.id)}>
          <span className="hub-scheme-preview" style={{ background: s.swatch[0] }}>
            <span className="hub-scheme-accent" style={{ background: s.swatch[1] }} />
          </span>
          <span className="hub-scheme-nm">{s.name}{value === s.id && <LBIcon name="check" size={13} />}</span>
          <span className="hub-scheme-ds">{s.desc}</span>
        </button>
      ))}
    </div>
  );
}
// 可拖拽排序的动作列表
function SortableActions({ order, setOrder }) {
  const dragId = useRef(null);
  const [overId, setOverId] = useState(null);
  const byId = (id) => ACTION_ITEMS.find((a) => a.id === id);
  const onDrop = (targetId) => {
    const from = order.indexOf(dragId.current), to = order.indexOf(targetId);
    if (from < 0 || to < 0 || from === to) return;
    const next = order.slice(); next.splice(to, 0, next.splice(from, 1)[0]); setOrder(next);
    dragId.current = null; setOverId(null);
  };
  return (
    <div className="hub-sortable">
      {order.map((id, i) => {
        const a = byId(id);
        return (
          <div key={id} className="hub-sort-row" draggable
            data-over={overId === id || undefined}
            onDragStart={() => (dragId.current = id)}
            onDragOver={(e) => { e.preventDefault(); setOverId(id); }}
            onDragLeave={() => setOverId((o) => (o === id ? null : o))}
            onDrop={() => onDrop(id)}
            onDragEnd={() => setOverId(null)}>
            <span className="hub-sort-grip"><LBIcon name="grip" size={16} /></span>
            <span className="hub-sort-idx">{i + 1}</span>
            <span className="hub-sort-icon"><LBIcon name={a.icon} size={16} /></span>
            <span className="hub-sort-label">{a.label}</span>
            {a.note && <span className="hub-sort-note">{a.note}</span>}
          </div>
        );
      })}
    </div>
  );
}

Object.assign(window, {
  ItemCard, ItemDetail, TypeTag, ActionBadge, renderPattern,
  Toggle, Segmented, Select, SettingRow,
  Badge, GateBanner, Hotkey, SchemeGrid, SortableActions,
});
