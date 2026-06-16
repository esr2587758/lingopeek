// cards.jsx — 5 种类型定制卡片 + 详情抽屉。三套形态共享。
const { useState } = React;

// 句型占位符高亮：把 {…} 渲染成强调色片段
function renderPattern(text) {
  const parts = String(text).split(/(\{[^}]*\})/g);
  return parts.map((p, i) =>
    p.startsWith("{") && p.endsWith("}")
      ? <span className="ph" key={i}>{p.slice(1, -1)}</span>
      : <span key={i}>{p}</span>
  );
}

// 例句搭配词高亮
function renderColloc(text, colloc) {
  if (!colloc || !colloc.length) return text;
  const esc = colloc.map((c) => c.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
  const re = new RegExp("(" + esc.join("|") + ")", "gi");
  const parts = String(text).split(re);
  return parts.map((p, i) =>
    colloc.some((c) => c.toLowerCase() === p.toLowerCase())
      ? <em key={i}>{p}</em>
      : <span key={i}>{p}</span>
  );
}

// 类型标签
function TypeTag({ type }) {
  const m = LB_TYPE_META[type] || {};
  return (
    <span className="c-tag" data-type={type} title={m.hint}>{type}</span>
  );
}

// 类型特定正文
function CardBody({ item, expanded, onToggleOrigin }) {
  switch (item.type) {
    case "短语":
      return (
        <div className="cb cb-phrase">
          <div className="cb-phrase-line">
            <span className="ph-word" lang="en">{item.text}</span>
            {item.ipa && <span className="ph-ipa">{item.ipa}</span>}
          </div>
          <div className="cb-gloss">{item.meta}</div>
        </div>
      );
    case "句型":
      return (
        <div className="cb cb-pattern">
          <div className="pt-text" lang="en">{renderPattern(item.text)}</div>
          <div className="cb-gloss">{item.meta}</div>
        </div>
      );
    case "例句":
      return (
        <div className="cb cb-example">
          <div className="ex-sentence" lang="en">{renderColloc(item.text, item.colloc)}</div>
        </div>
      );
    case "英文":
      return (
        <div className="cb cb-rewrite">
          <div className="rw-en" lang="en">{item.text}</div>
          {expanded ? (
            <div className="rw-origin">{item.origin}</div>
          ) : (
            <button className="rw-origin-toggle" onClick={(e) => { e.stopPropagation(); onToggleOrigin(); }}>
              <LBIcon name="chevronDown" size={13} /> 看原文
            </button>
          )}
        </div>
      );
    case "文本":
      return (
        <div className="cb cb-text" data-lang={item.lang}>
          <div className="tx-excerpt" lang={item.lang === "en" ? "en" : "zh"}>{item.text}</div>
        </div>
      );
    default:
      return <div className="cb">{item.text}</div>;
  }
}

// 卡片操作（hover 浮出）：复制 / 重新唤起 Lingobar / 删除
function CardActions({ item, onCopy, onRelaunch, onDelete }) {
  const speakable = item.type === "短语" || item.type === "例句";
  return (
    <div className="c-actions" onClick={(e) => e.stopPropagation()}>
      {speakable && (
        <button className="c-actbtn" title="发音" onClick={() => onRelaunch(item, "发音")}>
          <LBIcon name="sound" size={15} />
        </button>
      )}
      <button className="c-actbtn" title="复制" onClick={() => onCopy(item)}>
        <LBIcon name="copy" size={15} />
      </button>
      <button className="c-actbtn" title="重新唤起 Lingobar" onClick={() => onRelaunch(item)}>
        <LBIcon name="spark" size={15} />
      </button>
      <button className="c-actbtn danger" title="删除" onClick={() => onDelete(item)}>
        <LBIcon name="trash" size={15} />
      </button>
    </div>
  );
}

// 单张卡片
function CCard({ item, variant, onCopy, onRelaunch, onDelete, onOpen, selected }) {
  const [originOpen, setOriginOpen] = useState(false);
  return (
    <div
      className="c-card"
      data-type={item.type}
      data-variant={variant}
      data-selected={selected || undefined}
      onClick={() => onOpen && onOpen(item)}
    >
      <span className="c-stripe" data-type={item.type} />
      <div className="c-card-top">
        <TypeTag type={item.type} />
        <span className="c-src">{item.src}</span>
      </div>
      <CardBody item={item} expanded={originOpen} onToggleOrigin={() => setOriginOpen(true)} />
      <CardActions item={item} onCopy={onCopy} onRelaunch={onRelaunch} onDelete={onDelete} />
    </div>
  );
}

// 详情抽屉（大库视图点卡片右侧滑出）
function CDetail({ item, onClose, onCopy, onRelaunch, onDelete }) {
  if (!item) return null;
  const m = LB_TYPE_META[item.type] || {};
  // 相关收藏：同类型其它条目，最多 3 条
  const related = LB_COLLECTION.filter((x) => x.type === item.type && x.id !== item.id).slice(0, 3);
  return (
    <div className="c-detail">
      <div className="c-detail-head">
        <TypeTag type={item.type} />
        <span className="c-detail-sub">{m.en} · {m.hint}</span>
        <button className="iconbtn" title="关闭" onClick={onClose} style={{ marginLeft: "auto" }}>
          <LBIcon name="close" size={16} />
        </button>
      </div>

      <div className="c-detail-body">
        <div className="c-detail-main" lang={item.lang === "zh" ? "zh" : "en"}>
          {item.type === "句型" ? renderPattern(item.text)
            : item.type === "例句" ? renderColloc(item.text, item.colloc)
            : item.text}
        </div>
        {item.ipa && <div className="c-detail-ipa">{item.ipa}</div>}
        {item.meta && <div className="c-detail-meta">{item.meta}</div>}
        {item.origin && (
          <div className="c-detail-field">
            <div className="c-detail-label">原文</div>
            <div className="c-detail-value">{item.origin}</div>
          </div>
        )}
        <div className="c-detail-field">
          <div className="c-detail-label">来源</div>
          <div className="c-detail-value c-detail-src">
            <LBIcon name="link" size={13} /> {item.src}
          </div>
        </div>

        {related.length > 0 && (
          <div className="c-detail-field">
            <div className="c-detail-label">同类收藏</div>
            <div className="c-detail-related">
              {related.map((r) => (
                <div className="c-related-item" key={r.id} lang="en" onClick={() => onRelaunch(r, null, true)}>
                  {r.type === "句型" ? renderPattern(r.text) : r.text}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="c-detail-foot">
        <button className="foot-btn" onClick={() => onCopy(item)}><LBIcon name="copy" size={15} /> 复制</button>
        <button className="foot-btn primary" onClick={() => onRelaunch(item)}><LBIcon name="spark" size={15} /> 重新唤起 Lingobar</button>
        <div className="foot-spacer" />
        <button className="foot-btn danger" onClick={() => onDelete(item)}><LBIcon name="trash" size={15} /> 删除</button>
      </div>
    </div>
  );
}

Object.assign(window, { CCard, CDetail, TypeTag, renderPattern, renderColloc });
