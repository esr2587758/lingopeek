// scene.jsx — two presentation variants for 追问, each wrapping the shared chat.
// Variant A「右侧停靠」: chat docks to the RIGHT of the result as a second column,
//   so a tall result keeps its own scroll and the conversation scrolls independently.
// Variant B「独立浮层对话窗」: a separate floating chat window opens over the result.
// Both driven by the same useFollowupChat + Thread/Composer.

const { useState: sUseState } = React;

/* --- the result content that precedes 追问, per mode.
   selection mode = a TALL 语法 result (this is the case the user flagged);
   input mode = a short 改写 result. --- */
function ResultBody({ mode }) {
  if (mode === "selection") {
    const s = FU_SELECTION;
    return (
      <div className="fu-result">
        <div className="fu-g-sentence" lang="en">{s.text}</div>
        <div className="fu-g-gloss" lang="zh">{s.gloss}</div>

        <div className="fu-g-caption">结构拆解</div>
        {s.blocks.map((b, i) => (
          <div className="fu-g-block" key={i}>
            <div className="fu-g-role">{b.role}</div>
            <div className="fu-g-block-body">
              <div className="fu-g-text" lang="en">{b.text}</div>
              <div className="fu-g-hint" lang="zh">{b.hint}</div>
            </div>
          </div>
        ))}

        <div className="fu-g-pattern">
          <div className="lbl">可复用句型</div>
          <div className="pt" lang="en">{s.pattern.en}</div>
          <div className="ptz" lang="zh">{s.pattern.zh}</div>
        </div>

        <div className="fu-g-caption">值得收藏</div>
        <div className="fu-g-phrases">
          {s.phrases.map((p, i) => (
            <div className="fu-g-phrase" key={i}>
              <span className="p-en" lang="en">{p.text}</span>
              <span className="p-zh" lang="zh">{p.zh}</span>
              <span className="p-kind">{p.kind}</span>
            </div>
          ))}
        </div>
      </div>
    );
  }
  const s = FU_INPUT;
  return (
    <div className="fu-result">
      <div className="fu-rewrite fu-rewrite-primary" lang="en">{s.primary}</div>
    </div>
  );
}

function ResultTitle({ mode }) {
  return (
    <div className="fu-panel-title"><span className="dot" /> {mode === "selection" ? "语法" : "改写"}</div>
  );
}

/* --- top pill (selection summary), shared chrome --- */
function Pill({ mode, onClose, children }) {
  const s = mode === "selection" ? FU_SELECTION : FU_INPUT;
  const body = mode === "selection" ? s.text : s.draft;
  return (
    <div className="fu-pill">
      <div className="fu-src">
        <div className="fu-src-meta"><span>{s.app}</span><span className="fu-src-dot" /><span>{s.doc}</span></div>
        <div className="fu-src-text" lang={mode === "selection" ? "en" : "zh"}>{body}</div>
      </div>
      {children}
      {onClose && <button className="fu-iconbtn" title="关闭" onClick={onClose}><LBIcon name="close" size={15} /></button>}
    </div>
  );
}

/* the 追问 entry button that lives in the result's footer */
function AskButton({ open, onOpen, label }) {
  return (
    <button className="fu-askbtn" data-active={open} onClick={onOpen}>
      <LBIcon name="chat" size={15} /> {label}
    </button>
  );
}

/* the conversation column body — shared by dock + window */
function ConvoBody({ mode, chat, ctx, anchored, setAnchored, onCopy, onCollect, emptyLead }) {
  return (
    <>
      {!chat.hasThread && (
        <div className="fu-empty">
          <div className="fu-empty-lead" lang="zh">{emptyLead}</div>
          <Suggestions mode={mode} onPick={() => chat.send()} disabled={chat.streaming} />
        </div>
      )}
      <Thread messages={chat.messages} onCopy={onCopy} onCollect={onCollect} />
    </>
  );
}

/* ============================================================
   VARIANT A — 右侧停靠 (right-side dock)
   Result stays a fixed-width left column with its OWN scroll;
   chat slides in as a right column with its OWN scroll.
   ============================================================ */
function VariantDock({ mode, flash }) {
  const chat = useFollowupChat(mode);
  const [open, setOpen] = sUseState(true); // start open so the split reads at a glance
  const [anchored, setAnchored] = sUseState(true);
  const ctx = FU_CONTEXTS[mode];
  const onCopy = () => flash("已复制");
  const onCollect = () => flash("已收藏到「收藏」");
  const emptyLead = mode === "selection" ? "关于这次语法拆解，想继续问点什么？" : "关于这次改写，想继续问点什么？";

  return (
    <div className="fu-stage-col">
      {/* full-height two-column layout: left = pill + result stack; right = equal-height chat pane */}
      <div className={"fu-dock2col" + (open ? " is-open" : "")}>
        {/* LEFT — the existing panel (pill + result), its own scroll */}
        <div className="fu-leftstack">
          <Pill mode={mode} />
          <div className="fu-panel">
            <ResultTitle mode={mode} />
            <div className="fu-resultscroll">
              <ResultBody mode={mode} />
            </div>
            <div className="fu-resultfoot">
              <button className="fu-mini" onClick={onCopy}><LBIcon name="copy" size={13} /> 复制</button>
              <button className="fu-mini" onClick={onCollect}><LBIcon name="star" size={13} /> 收藏</button>
              {!open && <div className="fu-foot-spacer" />}
              {!open && <AskButton open={open} onOpen={() => setOpen(true)} label="追问" />}
            </div>
          </div>
        </div>

        {/* RIGHT — full-height 追问 pane, own header + scroll + composer */}
        {open && (
          <div className="fu-chatpane">
            <div className="fu-dock-cap">
              <span className="fu-dock-title"><LBIcon name="chat" size={14} /> 追问</span>
              <ContextChip ctx={ctx} anchored={anchored} onToggle={() => setAnchored((a) => !a)} />
              <button className="fu-iconbtn" title="收起追问" onClick={() => setOpen(false)}><LBIcon name="close" size={15} /></button>
            </div>
            <div className="fu-dock-scroll">
              <ConvoBody mode={mode} chat={chat} ctx={ctx} anchored={anchored} setAnchored={setAnchored} onCopy={onCopy} onCollect={onCollect} emptyLead={emptyLead} />
            </div>
            <div className="fu-dock-foot">
              <Composer mode={mode} streaming={chat.streaming} nextPrompt={chat.nextPrompt} exhausted={chat.exhausted} onSend={() => chat.send()} />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

/* ============================================================
   VARIANT B — 独立浮层对话窗 (floating window)
   ============================================================ */
function VariantWindow({ mode, flash }) {
  const chat = useFollowupChat(mode);
  const [open, setOpen] = sUseState(true);
  const [anchored, setAnchored] = sUseState(true);
  const ctx = FU_CONTEXTS[mode];
  const onCopy = () => flash("已复制");
  const onCollect = () => flash("已收藏到「收藏」");
  const emptyLead = mode === "selection" ? "关于这次语法拆解，想继续问点什么？" : "关于这次改写，想继续问点什么？";
  const closeWin = () => { setOpen(false); chat.reset(); };

  return (
    <div className="fu-stage-col">
      <div className="fu-panelmodel" data-dim={open}>
        <Pill mode={mode} />
        <div className="fu-panel">
          <ResultTitle mode={mode} />
          <div className="fu-resultscroll fu-resultscroll-solo">
            <ResultBody mode={mode} />
          </div>
          <div className="fu-resultfoot">
            <button className="fu-mini" onClick={onCopy}><LBIcon name="copy" size={13} /> 复制</button>
            <button className="fu-mini" onClick={onCollect}><LBIcon name="star" size={13} /> 收藏</button>
            <div className="fu-foot-spacer" />
            <AskButton open={open} onOpen={() => setOpen(true)} label="追问 · 打开对话" />
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
            <ConvoBody mode={mode} chat={chat} ctx={ctx} anchored={anchored} setAnchored={setAnchored} onCopy={onCopy} onCollect={onCollect} emptyLead={emptyLead} />
          </div>
          <div className="fu-chatwin-foot">
            <Composer mode={mode} streaming={chat.streaming} nextPrompt={chat.nextPrompt} exhausted={chat.exhausted} onSend={() => chat.send()} />
          </div>
        </div>
      )}
    </div>
  );
}

Object.assign(window, { VariantDock, VariantWindow, ResultBody, ResultTitle, Pill });
