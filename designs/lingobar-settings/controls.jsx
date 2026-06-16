// controls.jsx — 可复用设置控件
const { useState } = React;

// 行：标题 + 说明 + 右侧控件
function Row({ title, desc, children, gate }) {
  return (
    <div className="st-row">
      <div className="st-row-label">
        <div className="st-row-title">{title}{gate && <span className="st-gate-dot" title="必填项" />}</div>
        {desc && <div className="st-row-desc">{desc}</div>}
      </div>
      <div className="st-row-ctrl">{children}</div>
    </div>
  );
}

// 分组卡片
function Group({ title, children }) {
  return (
    <div className="st-group">
      {title && <div className="st-group-title">{title}</div>}
      <div className="st-group-body">{children}</div>
    </div>
  );
}

// 开关
function Toggle({ on, onChange }) {
  return (
    <button className="st-toggle" data-on={on} onClick={() => onChange(!on)} role="switch" aria-checked={on}>
      <span className="st-toggle-knob" />
    </button>
  );
}

// 分段控件
function Segmented({ options, value, onChange }) {
  return (
    <div className="st-seg">
      {options.map((o) => (
        <button key={o} className="st-seg-opt" data-on={o === value} onClick={() => onChange(o)}>{o}</button>
      ))}
    </div>
  );
}

// 下拉选择
function Select({ options, value, onChange }) {
  return (
    <div className="st-select">
      <select value={value} onChange={(e) => onChange(e.target.value)}>
        {options.map((o) => <option key={o} value={o}>{o}</option>)}
      </select>
      <LBIcon name="chevronDown" size={14} />
    </div>
  );
}

// 文本输入（含密文）
function TextField({ value, onChange, placeholder, secret, mono }) {
  const [reveal, setReveal] = useState(false);
  return (
    <div className="st-input" data-mono={mono || undefined}>
      <input
        type={secret && !reveal ? "password" : "text"}
        value={value} placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
      />
      {secret && (
        <button className="st-input-reveal" onClick={() => setReveal((r) => !r)}>{reveal ? "隐藏" : "显示"}</button>
      )}
    </div>
  );
}

// 状态徽章
function Badge({ kind, children }) {
  return <span className="st-badge" data-kind={kind}>{children}</span>;
}

// 快捷键显示
function Hotkey({ keys }) {
  return (
    <span className="st-hotkey">
      {keys.map((k, i) => <kbd key={i}>{k}</kbd>)}
    </span>
  );
}

Object.assign(window, { Row, Group, Toggle, Segmented, Select, TextField, Badge, Hotkey });
