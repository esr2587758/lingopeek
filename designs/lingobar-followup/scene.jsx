// scene.jsx — the two presentation variants for 追问, each wrapping the shared chat.
// Variant A「面板内展开」: follow-up grows inside the existing result panel.
// Variant B「独立浮层对话窗」: a separate floating window opens for the conversation.
// Both are driven by the same useFollowupChat + Thread/Composer components.

const { useState: sUseState } = React;

/* --- the result-panel content that precedes 追问, per mode --- */
function ResultHead({ mode }) {
  if (mode === "selection") {
    const s = FU_SELECTION;
    return (
      <>
        <div className="fu-panel-title"><span className="dot" /> 翻译</div>
        <div className="fu-result">
          <div className="fu-gloss" lang="zh">{s.gloss}</div>
          <div className="fu-keyrow"><span className="k" lang="en">{s.key}</span><span className="kz" lang="zh">{s.keyZh}</span></div>
        </div>
      </>
    );
  }
  const s = FU_INPUT;
  return (
    <>
      <div className="fu-panel-title"><span className="dot" /> 改写</div>
      <div className="fu-result">
        <div className="fu-rewrite fu-rewrite-primary" lang="en">{s.primary}</div>
      </div>
    </>
  );
}

/* --- top pill (selection summary), shared chrome --- */
function Pill({ mode, onClose }) {
  const s = mode === "selection" ? FU_SELECTION : FU_INPUT;
  const body = mode === "selection" ? s.text : s.draft;
  return (
    <div className="fu-pill">
      <div className="fu-src">
        <div className="fu-src-meta"><span>{s.app}</span><span className="fu-src-dot" /><span>{s.doc}</span></div>
        <div className="fu-src-text" lang={mode === "selection" ? "en" : "zh"}>{body}</div>
      </div>
      {onClose && <button className="fu-iconbtn" title="关闭" onClick={onClose}><LBIcon name="close" size={15} /></button>}
    </div>
  );
}

/* ============================================================
   VARIANT A — 面板内展开
   The 追问 conversation unfolds *inside* the result panel,
   directly under the original result. One continuous surface.
   ============================================================ */
function VariantInline({ mode, flash }) {
  const chat = useFollowupChat(mode);
  const [anchored, setAnchored] = sUseState(true);
  const ctx = FU_CONTEXTS[mode];
  const onCopy = (t) => flash("已复制");
  const onCollect = (t) => flash("已收藏到「收藏」");

  return (
    <div className="fu-col">
      <div className="fu-col-cap"><span className="idx">A</span> 面板内展开 · 追问接在结果下方</div>
      <div className="fu-scene">
        <div className="fu-panelmodel">
          <Pill mode={mode} />
          <div className="fu-panel">
            <ResultHead mode={mode} />

            {/* the 追问 zone: entry button OR the growing conversation */}
            {!chat.hasThread ? (
              <div className="fu-askrow">
                <button className="fu-askbtn" onClick={() => chat.send()}>
                  <LBIcon name="chat" size={15} /> 追问 · 没懂/想深入
                </button>
                <div className="fu-ask-hint">对这条结果继续对话</div>
              </div>
            ) : (
              <div className="fu-inline-convo">
                <div className="fu-convo-cap">
                  <LBIcon name="chat" size={13} /> 追问
                  <ContextChip ctx={ctx} anchored={anchored} onToggle={() => setAnchored((a) => !a)} />
                </div>
                <Thread messages={chat.messages} onCopy={onCopy} onCollect={onCollect} compact />
                {!chat.hasThread && <Suggestions mode={mode} onPick={() => chat.send()} disabled={chat.streaming} />}
              </div>
            )}

            {chat.hasThread && (
              <div className="fu-panel-foot">
                <Composer mode={mode} streaming={chat.streaming} nextPrompt={chat.nextPrompt} exhausted={chat.exhausted} onSend={() => chat.send()} />
              </div>
            )}
          </div>
        </div>
      </div>
      <div className="fu-col-note">追问就在原结果下方长出来，上下文天然连续；面板会变长。</div>
    </div>
  );
}

/* ============================================================
   VARIANT B — 独立浮层对话窗
   A button opens a separate floating chat window (ChatGPT-like).
   The original context rides along as a card pinned to the top.
   ============================================================ */
function VariantWindow({ mode, flash }) {
  const chat = useFollowupChat(mode);
  const [open, setOpen] = sUseState(false);
  const [anchored, setAnchored] = sUseState(true);
  const ctx = FU_CONTEXTS[mode];
  const onCopy = () => flash("已复制");
  const onCollect = () => flash("已收藏到「收藏」");

  const openWin = () => { setOpen(true); };
  const closeWin = () => { setOpen(false); chat.reset(); };

  return (
    <div className="fu-col">
      <div className="fu-col-cap"><span className="idx">B</span> 独立浮层对话窗 · 专注对话</div>
      <div className="fu-scene">
        {/* the base result panel stays put; window floats above it */}
        <div className="fu-panelmodel" data-dim={open}>
          <Pill mode={mode} />
          <div className="fu-panel">
            <ResultHead mode={mode} />
            <div className="fu-askrow">
              <button className="fu-askbtn" data-active={open} onClick={openWin}>
                <LBIcon name="chat" size={15} /> 追问 · 打开对话
              </button>
              <div className="fu-ask-hint">在独立窗口里深入</div>
            </div>
          </div>
        </div>

        {open && (
          <div className="fu-chatwin">
            <div className="fu-chatwin-bar">
              <div className="fu-chatwin-title"><LBIcon name="chat" size={15} /> 追问</div>
              <ContextChip ctx={ctx} anchored={anchored} onToggle={() => setAnchored((a) => !a)} />
              <button className="fu-iconbtn" title="关闭" onClick={closeWin}><LBIcon name="close" size={15} /></button>
            </div>
            <div className="fu-chatwin-body">
              {!chat.hasThread && (
                <div className="fu-empty">
                  <div className="fu-empty-lead" lang="zh">
                    {mode === "selection" ? "关于这句翻译，想继续问点什么？" : "关于这次改写，想继续问点什么？"}
                  </div>
                  <Suggestions mode={mode} onPick={() => chat.send()} disabled={chat.streaming} />
                </div>
              )}
              <Thread messages={chat.messages} onCopy={onCopy} onCollect={onCollect} />
            </div>
            <div className="fu-chatwin-foot">
              <Composer mode={mode} streaming={chat.streaming} nextPrompt={chat.nextPrompt} exhausted={chat.exhausted} onSend={() => chat.send()} />
            </div>
          </div>
        )}
      </div>
      <div className="fu-col-note">对话独立成窗，空间更大、更专注；与原结果分离，靠顶部卡片保留上下文。</div>
    </div>
  );
}

Object.assign(window, { VariantInline, VariantWindow, ResultHead, Pill });
