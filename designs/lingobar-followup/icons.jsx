// icons.jsx — SF-style line icons. Single stroke weight, currentColor, 24 viewBox.
// Superset of the lingobar-interactions set + follow-up/chat glyphs.

const LBIcon = ({ name, size = 18, stroke = 1.75, ...rest }) => {
  const common = {
    width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: stroke,
    strokeLinecap: "round", strokeLinejoin: "round", ...rest,
  };
  return <svg {...common}>{LB_ICON_PATHS[name] || null}</svg>;
};

const LB_ICON_PATHS = {
  translate: (
    <>
      <path d="M4 5h7" /><path d="M7.5 5c0 4-1.8 7.5-4 9.5" />
      <path d="M5 9.5c1.4 2 3.4 3.4 5.5 4" /><path d="M12.5 20l3.5-9 3.5 9" /><path d="M13.7 17h4.6" />
    </>
  ),
  rewrite: (
    <>
      <path d="M4 20h4l9.5-9.5a2 2 0 0 0-2.8-2.8L5 17.2V20z" /><path d="M13.5 6.5l4 4" />
    </>
  ),
  star: <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" />,
  copy: (
    <>
      <rect x="9" y="9" width="10" height="11" rx="2" /><path d="M5 15V6a2 2 0 0 1 2-2h8" />
    </>
  ),
  close: (
    <>
      <path d="M6 6l12 12" /><path d="M18 6L6 18" />
    </>
  ),
  check: <path d="M5 12.5l4 4 10-10" />,
  // 追问 / conversation — speech turns
  chat: (
    <>
      <path d="M4 6.5A2.5 2.5 0 0 1 6.5 4h11A2.5 2.5 0 0 1 20 6.5v6a2.5 2.5 0 0 1-2.5 2.5H9l-4 4v-4H6.5" />
    </>
  ),
  // ask — question spark
  ask: (
    <>
      <path d="M9 9a3 3 0 1 1 4 2.8c-.8.4-1 .9-1 1.7v.5" /><circle cx="12" cy="17.5" r="0.6" fill="currentColor" stroke="none" />
      <path d="M4 6.5A2.5 2.5 0 0 1 6.5 4h11A2.5 2.5 0 0 1 20 6.5v6a2.5 2.5 0 0 1-2.5 2.5H9l-4 4v-4" opacity="0" />
    </>
  ),
  // send — arrow up (composer)
  send: (
    <>
      <path d="M12 20V5" /><path d="M6 11l6-6 6 6" />
    </>
  ),
  // link / anchor context
  anchor: (
    <>
      <path d="M9.5 13.5l5-5" /><path d="M8 11L6.2 12.8a3 3 0 0 0 4.2 4.2L12 15.4" />
      <path d="M16 13l1.8-1.8a3 3 0 0 0-4.2-4.2L12 8.6" />
    </>
  ),
  mic: (
    <>
      <rect x="9" y="3.5" width="6" height="11" rx="3" /><path d="M6 11a6 6 0 0 0 12 0" /><path d="M12 17v3" />
    </>
  ),
  spark: (
    <>
      <path d="M12 4v4M12 16v4M4 12h4M16 12h4" /><path d="M7 7l2 2M15 15l2 2M17 7l-2 2M9 15l-2 2" />
    </>
  ),
  // small avatar mark for the assistant
  bar: (
    <>
      <rect x="4" y="4" width="16" height="16" rx="5" /><path d="M8 13c1.4 1.6 6.6 1.6 8 0" /><path d="M9 9.5h.01M15 9.5h.01" />
    </>
  ),
  arrowRight: <path d="M5 12h14M13 6l6 6-6 6" />,
  expand: (
    <>
      <path d="M8 4H4v4" /><path d="M16 4h4v4" /><path d="M8 20H4v-4" /><path d="M16 20h4v-4" />
    </>
  ),
  stop: <rect x="7" y="7" width="10" height="10" rx="2.5" fill="currentColor" stroke="none" />,
  regen: (
    <>
      <path d="M19 5v5h-5" /><path d="M18.5 10a7 7 0 1 0 .3 5" />
    </>
  ),
};

Object.assign(window, { LBIcon, LB_ICON_PATHS });
