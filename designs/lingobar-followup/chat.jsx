// chat.jsx — the shared 追问 conversation: streaming hook + thread + composer.
// Pure text, token-streamed. Reused by both presentation variants.

const { useState: cUseState, useEffect: cUseEffect, useRef: cUseRef, useCallback: cUseCallback } = React;

/* ---------------------------------------------------------------
   useFollowupChat — owns the message list + fake token streaming.
   Advances through the scripted FU_THREADS[mode] on each "send".
   --------------------------------------------------------------- */
function useFollowupChat(mode) {
  const script = FU_THREADS[mode];
  const [messages, setMessages] = cUseState([]); // {role, text, key?, rewrite?, streaming?}
  const [streaming, setStreaming] = cUseState(false);
  const [step, setStep] = cUseState(0);           // index into script (user turns consumed)
  const timers = cUseRef([]);

  const clearTimers = cUseCallback(() => { timers.current.forEach(clearTimeout); timers.current = []; }, []);
  cUseEffect(() => clearTimers, [clearTimers]);

  // stream one assistant turn, chunk by chunk
  const streamAssistant = cUseCallback((turn) => {
    setStreaming(true);
    setMessages((m) => [...m, { role: "assistant", text: "", key: turn.key, rewrite: turn.rewrite, streaming: true }]);
    let acc = "";
    let t = 260; // small "thinking" gap before first token
    turn.chunks.forEach((ch, i) => {
      const id = setTimeout(() => {
        acc += ch;
        setMessages((m) => {
          const copy = m.slice();
          copy[copy.length - 1] = { ...copy[copy.length - 1], text: acc };
          return copy;
        });
        if (i === turn.chunks.length - 1) {
          const done = setTimeout(() => {
            setMessages((m) => {
              const copy = m.slice();
              copy[copy.length - 1] = { ...copy[copy.length - 1], streaming: false };
              return copy;
            });
            setStreaming(false);
          }, 90);
          timers.current.push(done);
        }
      }, t);
      timers.current.push(id);
      t += 46 + ch.length * 15; // pace roughly by chunk length
    });
  }, []);

  // send a user turn (text optional — scripted reply is what matters for the mock)
  const send = cUseCallback((overrideText) => {
    if (streaming) return;
    const userTurn = script[step * 2];
    const asstTurn = script[step * 2 + 1];
    if (!userTurn || !asstTurn) return; // script exhausted
    setMessages((m) => [...m, { role: "user", text: overrideText || userTurn.text }]);
    setStep((s) => s + 1);
    const id = setTimeout(() => streamAssistant(asstTurn), 120);
    timers.current.push(id);
  }, [streaming, script, step, streamAssistant]);

  const reset = cUseCallback(() => {
    clearTimers();
    setMessages([]); setStreaming(false); setStep(0);
  }, [clearTimers]);

  const nextPrompt = script[step * 2]?.text || null;   // the next scripted user question
  const exhausted = step * 2 >= script.length;
  return { messages, streaming, send, reset, nextPrompt, exhausted, hasThread: messages.length > 0 };
}

/* ---------------- render one message's text w/ light markdown ---------------- */
function fmt(text) {
  // supports **bold**, *em*, and line breaks; everything else literal.
  const lines = text.split("\n");
  return lines.map((line, li) => {
    const parts = [];
    const re = /(\*\*[^*]+\*\*|\*[^*]+\*)/g;
    let last = 0, m;
    while ((m = re.exec(line)) !== null) {
      if (m.index > last) parts.push(line.slice(last, m.index));
      const tok = m[0];
      if (tok.startsWith("**")) parts.push(<strong key={li + "-" + m.index}>{tok.slice(2, -2)}</strong>);
      else parts.push(<em key={li + "-" + m.index}>{tok.slice(1, -1)}</em>);
      last = m.index + tok.length;
    }
    if (last < line.length) parts.push(line.slice(last));
    return (
      <React.Fragment key={li}>
        {li > 0 && <br />}
        {parts.length ? parts : line}
      </React.Fragment>
    );
  });
}

/* ---------------- message thread ---------------- */
function Thread({ messages, onCopy, onCollect, compact }) {
  const endRef = cUseRef(null);
  cUseEffect(() => { endRef.current?.scrollIntoView({ behavior: "smooth", block: "end" }); }, [messages]);
  return (
    <div className={"fu-thread" + (compact ? " is-compact" : "")}>
      {messages.map((msg, i) =>
        msg.role === "user" ? (
          <div className="fu-msg fu-msg-user" key={i}>
            <div className="fu-bubble" lang="zh">{fmt(msg.text)}</div>
          </div>
        ) : (
          <div className="fu-msg fu-msg-asst" key={i}>
            <div className="fu-avatar"><LBIcon name="bar" size={16} /></div>
            <div className="fu-asst-col">
              <div className="fu-answer" lang="zh">
                {fmt(msg.text)}
                {msg.streaming && <span className="fu-caret" />}
              </div>
              {!msg.streaming && msg.key && (
                <div className="fu-keychip"><span className="k" lang="en">{msg.key.term}</span><span className="kz" lang="zh">{msg.key.zh}</span></div>
              )}
              {!msg.streaming && msg.rewrite && (
                <div className="fu-rewrite" lang="en">{msg.rewrite}</div>
              )}
              {!msg.streaming && (msg.rewrite || msg.key) && (
                <div className="fu-msg-acts">
                  <button className="fu-mini" onClick={() => onCopy(msg.rewrite || msg.key.term)}><LBIcon name="copy" size={13} /> 复制</button>
                  <button className="fu-mini" onClick={() => onCollect(msg.rewrite || msg.key.term)}><LBIcon name="star" size={13} /> 收藏</button>
                </div>
              )}
            </div>
          </div>
        )
      )}
      <div ref={endRef} />
    </div>
  );
}

/* ---------------- suggestion chips (shown before first message) ---------------- */
function Suggestions({ mode, onPick, disabled }) {
  return (
    <div className="fu-suggests">
      {FU_SUGGESTIONS[mode].map((s, i) => (
        <button key={i} className="fu-suggest" disabled={disabled} onClick={() => onPick(s)}>
          <LBIcon name="ask" size={14} /> {s}
        </button>
      ))}
    </div>
  );
}

/* ---------------- context chip (anchored selection / result) ---------------- */
function ContextChip({ ctx, anchored, onToggle }) {
  return (
    <button className="fu-ctx" data-off={!anchored} onClick={onToggle} title={anchored ? "点按取消锚定，可自由提问" : "点按锚定当前上下文"}>
      <LBIcon name="anchor" size={13} />
      <span className="fu-ctx-kind">{anchored ? ctx.kind : "自由提问"}</span>
      <span className="fu-ctx-text" lang="en">{anchored ? ctx.text : "未锚定上下文"}</span>
    </button>
  );
}

/* ---------------- composer ---------------- */
function Composer({ mode, streaming, nextPrompt, exhausted, onSend }) {
  const [val, setVal] = cUseState("");
  // when a fresh scripted prompt is available, offer it as a soft placeholder
  const placeholder = exhausted ? "本演示的脚本对话已结束" : (nextPrompt ? "追问：" + nextPrompt : "继续追问…");
  const fire = () => {
    if (streaming || exhausted) return;
    onSend(val.trim() || undefined);
    setVal("");
  };
  return (
    <div className="fu-composer" data-disabled={exhausted}>
      <button className="fu-comp-mic" title="语音输入（MVP 暂未开放）" disabled><LBIcon name="mic" size={16} /></button>
      <textarea
        className="fu-comp-input"
        rows={1}
        value={val}
        placeholder={placeholder}
        disabled={streaming || exhausted}
        onChange={(e) => setVal(e.target.value)}
        onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); fire(); } }}
      />
      <button className="fu-comp-send" onClick={streaming ? undefined : fire} data-stop={streaming} disabled={exhausted} title={streaming ? "生成中" : "发送 (⏎)"}>
        <LBIcon name={streaming ? "stop" : "send"} size={16} />
      </button>
    </div>
  );
}

Object.assign(window, { useFollowupChat, Thread, Suggestions, ContextChip, Composer, fmt });
