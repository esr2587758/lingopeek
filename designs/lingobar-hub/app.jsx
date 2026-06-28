// app.jsx — Lingobar 主窗口（收藏 | 历史 | 设置）编排
const { useState, useMemo, useRef } = React;

function App() {
  const [section, setSection] = useState("collection");
  const [toast, setToast] = useState("");
  const toastT = useRef(null);
  const flash = (m) => { setToast(m); clearTimeout(toastT.current); toastT.current = setTimeout(() => setToast(""), 1700); };

  // 收藏 / 历史 数据（可变：删除、转存）
  const [coll, setColl] = useState(COLLECTION);
  const [hist, setHist] = useState(HISTORY);

  // setup gate：演示用，已配置好
  const apiKey = "sk-ant-••••••••••••";
  const gateOk = apiKey.length > 0;

  const flatNav = HUB_NAV.flatMap((g) => g.items);
  const cur = flatNav.find((s) => s.id === section);

  return (
    <div className="stage">
      <div className="wallpaper" />
      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span><span className="mb-item">编辑</span><span className="mb-item">窗口</span>
        <div className="mb-right"><span className="mono">周日 14:32</span><span>🔋 86%</span></div>
      </div>

      <div className="hubwin">
        {/* 左导航 */}
        <div className="hub-side">
          <div className="hub-side-brand">
            <span className="hub-brand-logo"><LBIcon name="spark" size={16} /></span>
            <span className="hub-brand-name">Lingobar</span>
          </div>
          <div className="hub-side-nav">
            {HUB_NAV.map((g) => (
              <div className="hub-navgroup" key={g.group}>
                <div className="hub-navgroup-title">{g.group}</div>
                {g.items.map((s) => (
                  <button key={s.id} className="hub-navitem" data-active={section === s.id} onClick={() => setSection(s.id)}>
                    <span className="hub-navicon"><LBIcon name={s.icon} size={17} /></span>
                    <span className="hub-navtext">
                      <span className="hub-navname">{s.name}</span>
                      <span className="hub-navdesc">{s.desc}</span>
                    </span>
                    {s.id === "collection" && <span className="hub-navcount">{coll.length}</span>}
                    {s.id === "history" && <span className="hub-navcount">{hist.length}</span>}
                  </button>
                ))}
              </div>
            ))}
          </div>
          {/* setup gate 状态条 */}
          <div className="hub-side-foot">
            <div className="hub-gate" data-ok={gateOk || undefined}>
              <LBIcon name={gateOk ? "check" : "alert"} size={13} />
              {gateOk ? "已就绪" : "需完成必填项"}
            </div>
          </div>
        </div>

        {/* 主区 */}
        <div className="hub-main">
          {section === "collection" && (
            <LibraryPane key="coll" mode="collection" items={coll} setItems={setColl} flash={flash} />
          )}
          {section === "history" && (
            <LibraryPane key="hist" mode="history" items={hist} setItems={setHist}
              flash={flash}
              onSaveToColl={(it) => { setColl((a) => [{ ...it, id: "c_" + it.id }, ...a]); flash("已转存到收藏"); }} />
          )}
          {section === "settings" && <SettingsPane apiKey={apiKey} gateOk={gateOk} flash={flash} />}
        </div>
      </div>

      {toast && <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>}
    </div>
  );
}

// ---- 收藏 / 历史 两栏（同构） ----
function LibraryPane({ mode, items, setItems, flash, onSaveToColl }) {
  const isHist = mode === "history";
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState("全部");
  const [detail, setDetail] = useState(null);

  const filterOptions = isHist ? HISTORY_ACTIONS : COLL_TYPES;
  const filterKey = isHist ? "action" : "type";

  const list = useMemo(() => {
    let arr = items;
    if (filter !== "全部") arr = arr.filter((x) => x[filterKey] === filter);
    if (query.trim()) {
      const q = query.toLowerCase();
      arr = arr.filter((x) => x.text.toLowerCase().includes(q) || (x.meta || "").toLowerCase().includes(q));
    }
    // 收藏按收藏时间，历史按最近
    return [...arr].sort((a, b) => a.when - b.when);
  }, [items, filter, query]);

  const onDelete = (it) => { setItems((a) => a.filter((x) => x.id !== it.id)); if (detail?.id === it.id) setDetail(null); flash("已删除"); };
  const onSave = (it) => {
    setItems((a) => a.map((x) => x.id === it.id ? { ...x, status: "saved" } : x));
    if (onSaveToColl) onSaveToColl(it);
  };
  const cardProps = {
    mode, onOpen: setDetail,
    onCopy: () => flash("已复制"), onPlay: (it) => flash("▶ " + it.text.slice(0, 24)),
    onRelaunch: (it) => flash("重新唤起浮层：" + (it.action || it.type)), onSave, onDelete,
  };

  return (
    <div className="hub-pane">
      {/* 头 + 工具栏 */}
      <div className="hub-pane-head">
        <div className="hub-pane-title">{isHist ? "历史" : "收藏"}<span className="hub-pane-count">{list.length}</span></div>
        <div className="hub-search">
          <LBIcon name="search" size={14} />
          <input placeholder={isHist ? "搜索历史…" : "搜索收藏…"} value={query} onChange={(e) => setQuery(e.target.value)} />
        </div>
      </div>
      <div className="hub-toolbar">
        <div className="hub-filterchips">
          {filterOptions.map((o) => (
            <button key={o} className="hub-chip" data-on={filter === o || undefined} onClick={() => setFilter(o)}>{o}</button>
          ))}
        </div>
        {isHist && <button className="hub-clear" onClick={() => flash("（演示）清空历史")}>清空</button>}
      </div>

      {/* 两栏：列表 + 详情 */}
      <div className="hub-twocol">
        <div className="hub-list">
          {list.length === 0 && <div className="hub-empty">没有匹配的条目</div>}
          {list.map((it) => (
            <ItemCard key={it.id} item={it} selected={detail?.id === it.id} {...cardProps} />
          ))}
        </div>
        <ItemDetail item={detail} mode={mode}
          onClose={() => setDetail(null)}
          onCopy={() => flash("已复制")} onPlay={(it) => flash("▶ " + it.text.slice(0, 24))}
          onRelaunch={(it) => flash("重新唤起浮层：" + (it.action || it.type))}
          onSave={onSave} onDelete={onDelete} />
      </div>
    </div>
  );
}

// ---- 设置 ----
function SettingsPane({ apiKey, gateOk, flash }) {
  const [sub, setSub] = useState("general");
  const [cfg, setCfg] = useState({
    launch: true, menubar: true, appearance: "tool",
    provider: "Claude (Anthropic)", model: "claude-opus-4-8",
    accessibility: true, mic: false,
    selFirst: true, floatBtn: true, defEn: "翻译", defZh: "改写",
    collectMode: "follow", autoTag: true, dedupe: true,
  });
  const set = (k, v) => setCfg((c) => ({ ...c, [k]: v }));
  const [actions, setActions] = useState(ACTION_ITEMS.map((a) => a.id));

  return (
    <div className="hub-pane hub-settings">
      <div className="hub-pane-head">
        <div className="hub-pane-title">设置</div>
        <div className="hub-subnav">
          {HUB_SETTINGS_NAV.map((s) => (
            <button key={s.id} className="hub-subnav-item" data-on={sub === s.id} onClick={() => setSub(s.id)}>{s.name}</button>
          ))}
        </div>
      </div>
      <div className="hub-set-scroll">
        {sub === "general" && (
          <>
            <div className="hub-set-group">
              <div className="hub-set-grouptitle">启动</div>
              <div className="hub-set-card">
                <SettingRow title="开机时启动" desc="登录 macOS 后自动运行 Lingobar"><Toggle on={cfg.launch} onChange={(v) => set("launch", v)} /></SettingRow>
                <SettingRow title="显示菜单栏图标" desc="常驻入口，打开收藏 / 历史 / 设置"><Toggle on={cfg.menubar} onChange={(v) => set("menubar", v)} /></SettingRow>
              </div>
            </div>
            <div className="hub-set-group">
              <div className="hub-set-grouptitle">外观</div>
              <SchemeGrid value={cfg.appearance} onChange={(v) => set("appearance", v)} />
            </div>
          </>
        )}
        {sub === "ai" && (
          <div className="hub-set-group">
            {!gateOk && <GateBanner text="配置 AI 服务并授予辅助功能权限后，Lingobar 才能正常使用。" />}
            <div className="hub-set-grouptitle">模型服务</div>
            <div className="hub-set-card">
              <SettingRow title="服务商" desc="选择 AI 接入来源"><Select options={AI_PROVIDERS} value={cfg.provider} onChange={(v) => { set("provider", v); set("model", AI_MODELS[v][0]); }} /></SettingRow>
              <SettingRow title="模型"><Select options={AI_MODELS[cfg.provider]} value={cfg.model} onChange={(v) => set("model", v)} /></SettingRow>
              <SettingRow title="API Key" desc="密钥仅保存在本地钥匙串，不上传" required>
                <div className="hub-keyfield"><span lang="en">{apiKey}</span><button onClick={() => flash("（演示）编辑 Key")}>编辑</button></div>
              </SettingRow>
            </div>
          </div>
        )}
        {sub === "permissions" && (
          <div className="hub-set-group">
            <div className="hub-set-grouptitle">系统权限</div>
            <div className="hub-set-card">
              <SettingRow title="辅助功能 (Accessibility)" desc="读取其它 App 中的选中文本所必需" required>
                {cfg.accessibility
                  ? <Badge kind="ok"><LBIcon name="check" size={12} /> 已授权</Badge>
                  : <button className="hub-foot-btn primary" onClick={() => { set("accessibility", true); flash("已打开系统设置"); }}>去授权</button>}
              </SettingRow>
              <SettingRow title="麦克风" desc="语音输入暂未启用（MVP 不申请该权限）"><Badge kind="muted">未启用</Badge></SettingRow>
            </div>
            <p className="hub-foot-note">Lingobar 仅在你划词或主动唤起时读取当前选区，不会在后台持续监听。</p>
          </div>
        )}
        {sub === "trigger" && (
          <>
            <div className="hub-set-group">
              <div className="hub-set-grouptitle">划词唤起</div>
              <div className="hub-set-card">
                <SettingRow title="选中文本后唤起" desc="在任意 App 选中文字即显示 Lingobar（选区优先）"><Toggle on={cfg.selFirst} onChange={(v) => set("selFirst", v)} /></SettingRow>
                <SettingRow title="显示划词浮标" desc="先冒出小按钮，点击再展开，避免打扰"><Toggle on={cfg.floatBtn} onChange={(v) => set("floatBtn", v)} /></SettingRow>
              </div>
            </div>
            <div className="hub-set-group">
              <div className="hub-set-grouptitle">输入模式</div>
              <div className="hub-set-card">
                <SettingRow title="呼出快捷键" desc="无选区时唤起输入模式，把想法改写成自然英文"><Hotkey keys={["⌥", "Space"]} /></SettingRow>
              </div>
            </div>
          </>
        )}
        {sub === "actions" && (
          <>
            <div className="hub-set-group">
              <div className="hub-set-grouptitle">动作顺序</div>
              <p className="hub-inline-note">拖动调整 Lingobar 工具条里语言动作的排列优先级。</p>
              <SortableActions order={actions} setOrder={setActions} />
            </div>
            <div className="hub-set-group">
              <div className="hub-set-grouptitle">默认动作</div>
              <div className="hub-set-card">
                <SettingRow title="选中英文时" desc="打开 Lingobar 的默认动作"><Segmented options={["翻译", "语法", "改写", "例句"]} value={cfg.defEn} onChange={(v) => set("defEn", v)} /></SettingRow>
                <SettingRow title="选中中文 / 混合时" desc="中文或混合语言默认动作"><Segmented options={["改写", "翻译"]} value={cfg.defZh} onChange={(v) => set("defZh", v)} /></SettingRow>
              </div>
            </div>
          </>
        )}
        {sub === "collectionPref" && (
          <>
            <div className="hub-set-group">
              <div className="hub-set-grouptitle">收藏内容</div>
              <div className="hub-set-card">
                {COLLECT_MODES.map((m) => (
                  <button key={m.id} className="hub-radio-row" data-on={cfg.collectMode === m.id || undefined} onClick={() => set("collectMode", m.id)}>
                    <span className="hub-radio"><span className="hub-radio-dot" /></span>
                    <span className="hub-radio-text"><span className="hub-radio-title">{m.label}</span><span className="hub-radio-desc">{m.desc}</span></span>
                  </button>
                ))}
              </div>
            </div>
            <div className="hub-set-group">
              <div className="hub-set-grouptitle">整理</div>
              <div className="hub-set-card">
                <SettingRow title="自动按类型归类" desc="短语 / 句型 / 例句 / 英文自动打标签"><Toggle on={cfg.autoTag} onChange={(v) => set("autoTag", v)} /></SettingRow>
                <SettingRow title="去重提醒" desc="收藏已存在的内容时提示"><Toggle on={cfg.dedupe} onChange={(v) => set("dedupe", v)} /></SettingRow>
              </div>
            </div>
          </>
        )}
        {sub === "about" && (
          <div className="hub-about">
            <span className="hub-about-logo"><LBIcon name="spark" size={26} /></span>
            <div className="hub-about-name">Lingobar</div>
            <div className="hub-about-ver mono">v0.1.0 (MVP)</div>
            <div className="hub-about-desc">划词即解析 · 表达即改写 · 沉淀即复习</div>
          </div>
        )}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
