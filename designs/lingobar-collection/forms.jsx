// forms.jsx — 三套收藏形态：A 紧凑浮窗 / B 中等双栏 / C 大库视图
const { useMemo } = React;

// ---- 共享：筛选 + 搜索 + 排序/分组 ----
function useItems(items, { type, query, sort }) {
  return useMemo(() => {
    let out = items.slice();
    if (type && type !== "全部") out = out.filter((it) => it.type === type);
    if (query) {
      const q = query.toLowerCase();
      out = out.filter((it) =>
        (it.text + (it.meta || "") + (it.origin || "") + it.src).toLowerCase().includes(q)
      );
    }
    out.sort((a, b) => b.when - a.when); // 默认时间倒序
    return out;
  }, [items, type, query, sort]);
}

// 按类型分组（保留 LB_COLL_TYPES 顺序）
function groupByType(list) {
  return LB_COLL_TYPES
    .map((t) => ({ type: t, items: list.filter((x) => x.type === t) }))
    .filter((g) => g.items.length > 0);
}

function CountPill({ n }) {
  return <span className="coll-count">{n}</span>;
}

function EmptyState({ query }) {
  return (
    <div className="coll-empty">
      <LBIcon name={query ? "search" : "collection"} size={26} />
      <div className="coll-empty-title">{query ? "没有匹配的收藏" : "收藏是空的"}</div>
      <div className="coll-empty-sub">
        {query ? "换个关键词试试" : "划词后点「收藏」，内容会沉淀到这里"}
      </div>
    </div>
  );
}

// 视图切换段：分类 / 最近
function GroupToggle({ mode, onMode }) {
  return (
    <div className="seg-toggle">
      <button className="seg" data-on={mode === "type"} onClick={() => onMode("type")}>
        <LBIcon name="layers" size={13} /> 分类
      </button>
      <button className="seg" data-on={mode === "recent"} onClick={() => onMode("recent")}>
        <LBIcon name="clock" size={13} /> 最近
      </button>
    </div>
  );
}

/* =========================================================
   A — 紧凑浮窗（右上 392px，时间流为主 + 类型筛选）
   ========================================================= */
function CompactForm({ items, state, set, handlers }) {
  const list = useItems(items, state);
  return (
    <div className="collwin compact">
      <div className="coll-head">
        <div className="coll-title"><LBIcon name="collection" size={17} /> 收藏 <CountPill n={list.length} /></div>
        <button className="iconbtn" title="关闭" onClick={handlers.onCloseWin} style={{ marginLeft: "auto" }}>
          <LBIcon name="close" size={16} />
        </button>
      </div>
      <div className="coll-search">
        <LBIcon name="search" size={15} />
        <input placeholder="搜索收藏…" value={state.query} onChange={(e) => set.query(e.target.value)} />
      </div>
      <div className="coll-filters">
        {["全部", ...LB_COLL_TYPES].map((t) => (
          <button key={t} className="coll-filter" data-active={state.type === t} onClick={() => set.type(t)}>{t}</button>
        ))}
      </div>
      <div className="coll-list">
        {list.length === 0 ? <EmptyState query={state.query} /> : list.map((it) => (
          <CCard key={it.id} item={it} variant="compact" {...handlers} />
        ))}
      </div>
    </div>
  );
}

/* =========================================================
   B — 中等双栏（~640，左类型导航 + 右内容，分类/最近切换）
   ========================================================= */
function SplitForm({ items, state, set, handlers }) {
  const list = useItems(items, { ...state, type: "全部" }); // 左导航统计用全集
  const counts = useMemo(() => {
    const c = {};
    LB_COLL_TYPES.forEach((t) => (c[t] = 0));
    items.forEach((it) => { c[it.type] = (c[it.type] || 0) + 1; });
    return c;
  }, [items]);
  const shown = useItems(items, state);
  const groups = state.group === "type" && state.type === "全部" ? groupByType(shown) : null;

  return (
    <div className="splitwin">
      <div className="split-side">
        <div className="split-brand"><LBIcon name="collection" size={18} /> 收藏</div>
        <button className="split-navitem" data-active={state.type === "全部"} onClick={() => set.type("全部")}>
          <span>全部</span><span className="n">{items.length}</span>
        </button>
        <div className="split-nav-label">类型</div>
        {LB_COLL_TYPES.map((t) => (
          <button key={t} className="split-navitem" data-active={state.type === t} onClick={() => set.type(t)}>
            <span className="dot" data-type={t} /><span>{t}</span><span className="n">{counts[t]}</span>
          </button>
        ))}
      </div>
      <div className="split-main">
        <div className="split-toolbar">
          <div className="coll-search flat">
            <LBIcon name="search" size={15} />
            <input placeholder="搜索收藏…" value={state.query} onChange={(e) => set.query(e.target.value)} />
          </div>
          <GroupToggle mode={state.group} onMode={set.group} />
          <button className="iconbtn" title="关闭" onClick={handlers.onCloseWin}><LBIcon name="close" size={16} /></button>
        </div>
        <div className="split-scroll">
          {shown.length === 0 ? <EmptyState query={state.query} /> : groups ? (
            groups.map((g) => (
              <div className="coll-group" key={g.type}>
                <div className="coll-group-head"><TypeTag type={g.type} /> <span className="coll-group-n">{g.items.length}</span></div>
                {g.items.map((it) => <CCard key={it.id} item={it} variant="split" {...handlers} />)}
              </div>
            ))
          ) : (
            shown.map((it) => <CCard key={it.id} item={it} variant="split" {...handlers} />)
          )}
        </div>
      </div>
    </div>
  );
}

/* =========================================================
   C — 大库视图（接近全屏 ~960，网格 + 分段标题 + 详情抽屉）
   ========================================================= */
function LibraryForm({ items, state, set, handlers, detail }) {
  const shown = useItems(items, state);
  const groups = state.group === "type" && state.type === "全部" ? groupByType(shown) : null;

  return (
    <div className="libwin" data-detail={detail ? "true" : undefined}>
      <div className="lib-main">
        <div className="lib-head">
          <div className="lib-title"><LBIcon name="collection" size={22} /> 我的收藏 <CountPill n={shown.length} /></div>
          <div className="lib-search">
            <LBIcon name="search" size={16} />
            <input placeholder="搜索全部收藏…" value={state.query} onChange={(e) => set.query(e.target.value)} />
          </div>
          <GroupToggle mode={state.group} onMode={set.group} />
          <button className="iconbtn" title="关闭" onClick={handlers.onCloseWin}><LBIcon name="close" size={18} /></button>
        </div>
        <div className="lib-filters">
          {["全部", ...LB_COLL_TYPES].map((t) => (
            <button key={t} className="coll-filter" data-active={state.type === t} onClick={() => set.type(t)}>{t}</button>
          ))}
        </div>
        <div className="lib-scroll">
          {shown.length === 0 ? <EmptyState query={state.query} /> : groups ? (
            groups.map((g) => (
              <div className="lib-section" key={g.type}>
                <div className="lib-section-head"><TypeTag type={g.type} /> <span className="lib-section-en">{(LB_TYPE_META[g.type] || {}).en}</span> <span className="lib-section-n">{g.items.length}</span></div>
                <div className="lib-grid">
                  {g.items.map((it) => <CCard key={it.id} item={it} variant="lib" selected={detail && detail.id === it.id} {...handlers} />)}
                </div>
              </div>
            ))
          ) : (
            <div className="lib-grid">
              {shown.map((it) => <CCard key={it.id} item={it} variant="lib" selected={detail && detail.id === it.id} {...handlers} />)}
            </div>
          )}
        </div>
      </div>
      {detail && (
        <CDetail item={detail} onClose={handlers.onCloseDetail} onCopy={handlers.onCopy} onRelaunch={handlers.onRelaunch} onDelete={handlers.onDelete} />
      )}
    </div>
  );
}

Object.assign(window, { CompactForm, SplitForm, LibraryForm, useItems, groupByType });
