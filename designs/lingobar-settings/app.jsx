// app.jsx — Lingobar 设置：左右两栏（左 section 导航 + 右内容）
const { useState, useRef } = React;

function App() {
  const [section, setSection] = useState("general");
  const [cfg, setCfg] = useState({
    launchAtLogin: true,
    showMenuBar: true,
    appearance: "glass",
    provider: "Claude (Anthropic)",
    model: "claude-opus-4-8",
    apiKey: "",
    baseUrl: "",
    accessibility: true,
    micEnabled: false,
    triggerSelection: true,
    triggerFloatBtn: true,
    inputHotkey: ["⌥", "Space"],
    defaultEn: "翻译",
    defaultZh: "改写",
    collectTarget: "follow",
    autoReadClipboard: false,
  });
  const [actions, setActions] = useState(ACTION_ITEMS.map((a) => a.id));
  const [toast, setToast] = useState("");
  const toastT = useRef(null);
  const set = (k, v) => setCfg((c) => ({ ...c, [k]: v }));
  const flash = (m) => { setToast(m); clearTimeout(toastT.current); toastT.current = setTimeout(() => setToast(""), 1800); };

  // setup gate 状态
  const gateOk = cfg.accessibility && cfg.apiKey.trim().length > 0;
  const cur = SETTINGS_SECTIONS.find((s) => s.id === section);

  return (
    <div className="stage">
      <div className="wallpaper" />
      <div className="menubar">
        <span className="mb-app">Lingobar</span>
        <span className="mb-item">文件</span><span className="mb-item">编辑</span>
        <span className="mb-item">设置</span>
        <div className="mb-right"><span className="mono">周日 14:32</span><span>🔋 86%</span></div>
      </div>

      <div className="setwin">
        {/* 左导航 */}
        <div className="set-side">
          <div className="set-brand"><LBIcon name="gear" size={18} /> 设置</div>
          {SETTINGS_SECTIONS.map((s) => (
            <button key={s.id} className="set-navitem" data-active={section === s.id} onClick={() => setSection(s.id)}>
              <span className="set-navicon"><LBIcon name={s.icon} size={17} /></span>
              <span className="set-navtext">
                <span className="nm">{s.name}{s.gate && !gateOk && <span className="set-gate-flag" title="待完成" />}</span>
                <span className="ds">{s.desc}</span>
              </span>
            </button>
          ))}
          <div className="set-side-foot">
            <span className={"set-gate-pill" + (gateOk ? " ok" : "")}>
              <LBIcon name={gateOk ? "check" : "alert"} size={13} /> {gateOk ? "已就绪" : "需完成必填项"}
            </span>
          </div>
        </div>

        {/* 右内容 */}
        <div className="set-main">
          <div className="set-head">
            <div className="set-head-title">{cur.name}</div>
            <div className="set-head-desc">{cur.desc}</div>
          </div>
          <div className="set-scroll">
            {section === "general" && <GeneralSection cfg={cfg} set={set} />}
            {section === "ai" && <AISection cfg={cfg} set={set} gateOk={gateOk} />}
            {section === "permissions" && <PermSection cfg={cfg} set={set} flash={flash} />}
            {section === "trigger" && <TriggerSection cfg={cfg} set={set} />}
            {section === "actions" && <ActionsSection cfg={cfg} set={set} actions={actions} setActions={setActions} />}
            {section === "collection" && <CollectionSection cfg={cfg} set={set} />}
            {section === "about" && <AboutSection />}
          </div>
        </div>
      </div>

      {toast && <div className="toast"><LBIcon name="check" size={14} /> {toast}</div>}
    </div>
  );
}

/* ---------------- sections ---------------- */
function GeneralSection({ cfg, set }) {
  return (
    <>
      <Group title="启动">
        <Row title="开机时启动" desc="登录 macOS 后自动运行 Lingobar"><Toggle on={cfg.launchAtLogin} onChange={(v) => set("launchAtLogin", v)} /></Row>
        <Row title="显示菜单栏图标" desc="在系统菜单栏常驻入口"><Toggle on={cfg.showMenuBar} onChange={(v) => set("showMenuBar", v)} /></Row>
      </Group>
      <Group title="外观">
        <div className="st-scheme-grid">
          {APPEARANCE_SCHEMES.map((s) => (
            <button key={s.id} className="st-scheme" data-on={cfg.appearance === s.id} onClick={() => set("appearance", s.id)}>
              <span className="st-scheme-preview" style={{ background: s.swatch[0] }}>
                <span className="st-scheme-accent" style={{ background: s.swatch[1] }} />
              </span>
              <span className="st-scheme-nm">{s.name}{cfg.appearance === s.id && <LBIcon name="check" size={13} />}</span>
              <span className="st-scheme-ds">{s.desc}</span>
            </button>
          ))}
        </div>
      </Group>
    </>
  );
}

function AISection({ cfg, set, gateOk }) {
  return (
    <>
      {!gateOk && <GateBanner text="配置 AI 服务并授予辅助功能权限后，Lingobar 才能正常使用。" />}
      <Group title="模型服务">
        <Row title="服务商" desc="选择 AI 接入来源"><Select options={AI_PROVIDERS} value={cfg.provider} onChange={(v) => { set("provider", v); set("model", AI_MODELS[v][0]); }} /></Row>
        <Row title="模型"><Select options={AI_MODELS[cfg.provider]} value={cfg.model} onChange={(v) => set("model", v)} /></Row>
        <Row title="API Key" desc="密钥仅保存在本地钥匙串，不上传" gate>
          <TextField value={cfg.apiKey} onChange={(v) => set("apiKey", v)} placeholder="sk-…" secret mono />
        </Row>
        {cfg.provider === "自定义 / 兼容 OpenAI" && (
          <Row title="Base URL" desc="兼容 OpenAI 协议的接口地址">
            <TextField value={cfg.baseUrl} onChange={(v) => set("baseUrl", v)} placeholder="https://…/v1" mono />
          </Row>
        )}
      </Group>
    </>
  );
}

function PermSection({ cfg, set, flash }) {
  return (
    <>
      <Group title="系统权限">
        <Row title="辅助功能 (Accessibility)" desc="读取其它 App 中的选中文本所必需" gate>
          {cfg.accessibility
            ? <Badge kind="ok"><LBIcon name="check" size={12} /> 已授权</Badge>
            : <button className="st-btn primary" onClick={() => { set("accessibility", true); flash("已打开系统设置"); }}>去授权</button>}
        </Row>
        <Row title="麦克风" desc="语音输入暂未启用（MVP 不申请该权限）">
          <Badge kind="muted">未启用</Badge>
        </Row>
      </Group>
      <p className="st-foot-note">Lingobar 仅在你划词或主动唤起时读取当前选区，不会在后台持续监听。</p>
    </>
  );
}

function TriggerSection({ cfg, set }) {
  return (
    <>
      <Group title="划词唤起">
        <Row title="选中文本后唤起" desc="在任意 App 选中文字即显示 Lingobar（选区优先）"><Toggle on={cfg.triggerSelection} onChange={(v) => set("triggerSelection", v)} /></Row>
        <Row title="显示划词浮标" desc="先冒出小按钮，点击再展开，避免打扰"><Toggle on={cfg.triggerFloatBtn} onChange={(v) => set("triggerFloatBtn", v)} /></Row>
      </Group>
      <Group title="输入模式">
        <Row title="呼出快捷键" desc="无选区时唤起输入模式，把想法改写成自然英文">
          <Hotkey keys={cfg.inputHotkey} />
        </Row>
      </Group>
    </>
  );
}

function ActionsSection({ cfg, set, actions, setActions }) {
  return (
    <>
      <Group title="动作顺序">
        <p className="st-inline-note">拖动调整 Lingobar 工具条里语言动作的排列优先级。</p>
        <SortableActions order={actions} setOrder={setActions} />
      </Group>
      <Group title="默认动作">
        <Row title="选中英文时" desc="打开 Lingobar 的默认动作"><Segmented options={["翻译", "语法", "改写", "例句"]} value={cfg.defaultEn} onChange={(v) => set("defaultEn", v)} /></Row>
        <Row title="选中中文 / 混合时" desc="中文或混合语言默认动作"><Segmented options={["改写", "翻译"]} value={cfg.defaultZh} onChange={(v) => set("defaultZh", v)} /></Row>
      </Group>
    </>
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
    <div className="st-sortable">
      {order.map((id, i) => {
        const a = byId(id);
        return (
          <div key={id} className="st-sort-row" draggable
            data-over={overId === id || undefined}
            onDragStart={() => (dragId.current = id)}
            onDragOver={(e) => { e.preventDefault(); setOverId(id); }}
            onDragLeave={() => setOverId((o) => (o === id ? null : o))}
            onDrop={() => onDrop(id)}
            onDragEnd={() => setOverId(null)}>
            <span className="st-sort-grip"><LBIcon name="grip" size={16} /></span>
            <span className="st-sort-idx">{i + 1}</span>
            <span className="st-sort-icon"><LBIcon name={a.icon} size={16} /></span>
            <span className="st-sort-label">{a.label}</span>
            {a.note && <span className="st-sort-note">{a.note}</span>}
          </div>
        );
      })}
    </div>
  );
}

function CollectionSection({ cfg, set }) {
  return (
    <>
      <Group title="收藏行为">
        <p className="st-inline-note">按下「收藏」时，默认收藏的内容。</p>
        {COLLECT_TARGETS.map((t) => (
          <button key={t.id} className="st-radio-card" data-on={cfg.collectTarget === t.id} onClick={() => set("collectTarget", t.id)}>
            <span className="st-radio-dot" data-on={cfg.collectTarget === t.id} />
            <span className="st-radio-text">
              <span className="st-radio-title">{t.label}</span>
              <span className="st-radio-desc">{t.desc}</span>
            </span>
          </button>
        ))}
      </Group>
      <Group title="其它">
        <Row title="自动读取剪贴板" desc="打开输入模式时，自动填入剪贴板内容"><Toggle on={cfg.autoReadClipboard} onChange={(v) => set("autoReadClipboard", v)} /></Row>
      </Group>
    </>
  );
}

function AboutSection() {
  return (
    <Group>
      <div className="st-about">
        <div className="st-about-logo"><LBIcon name="gear" size={26} /></div>
        <div className="st-about-name">Lingobar</div>
        <div className="st-about-ver">版本 0.1.0 (MVP 原型)</div>
        <div className="st-about-desc">选区优先的英语阅读、表达与记忆工具。</div>
        <div className="st-about-links">
          <span className="st-about-link"><LBIcon name="link" size={13} /> 帮助</span>
          <span className="st-about-link"><LBIcon name="link" size={13} /> 反馈</span>
        </div>
      </div>
    </Group>
  );
}

function GateBanner({ text }) {
  return <div className="st-gate-banner"><LBIcon name="alert" size={16} /> <span>{text}</span></div>;
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
