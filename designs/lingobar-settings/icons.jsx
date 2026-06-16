// icons.jsx — reused from lingobar-collection + settings extras.
const LBIcon = ({ name, size = 18, stroke = 1.75, ...rest }) => {
  const common = { width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round", ...rest };
  return <svg {...common}>{LB_ICON_PATHS[name] || null}</svg>;
};
const LB_ICON_PATHS = {
  translate: (<><path d="M4 5h7" /><path d="M7.5 5c0 4-1.8 7.5-4 9.5" /><path d="M5 9.5c1.4 2 3.4 3.4 5.5 4" /><path d="M12.5 20l3.5-9 3.5 9" /><path d="M13.7 17h4.6" /></>),
  grammar: (<><path d="M5 7v10" /><path d="M5 7h3" /><path d="M5 17h3" /><path d="M19 7v10" /><path d="M19 7h-3" /><path d="M19 17h-3" /><path d="M9.5 12h5" /><circle cx="12" cy="12" r="0.6" fill="currentColor" stroke="none" /></>),
  rewrite: (<><path d="M4 20h4l9.5-9.5a2 2 0 0 0-2.8-2.8L5 17.2V20z" /><path d="M13.5 6.5l4 4" /></>),
  examples: (<><path d="M5 7h11" /><path d="M5 12h14" /><path d="M5 17h8" /></>),
  star: <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" />,
  sound: (<><path d="M5 9.5h3l4-3v11l-4-3H5z" /><path d="M16 9c1 1 1 5 0 6" /><path d="M18.5 7c2 2 2 8 0 10" /></>),
  copy: (<><rect x="9" y="9" width="10" height="11" rx="2" /><path d="M5 15V6a2 2 0 0 1 2-2h8" /></>),
  close: (<><path d="M6 6l12 12" /><path d="M18 6L6 18" /></>),
  search: (<><circle cx="11" cy="11" r="6" /><path d="M16 16l4 4" /></>),
  check: <path d="M5 12.5l4 4 10-10" />,
  collection: (<><path d="M5 6h14" /><path d="M5 11h14" /><path d="M5 16h9" /><path d="M17.5 16.5l1.5 1.5 2.5-3" /></>),
  chevronDown: <path d="M6 9l6 6 6-6" />,
  chevronRight: <path d="M9 6l6 6-6 6" />,
  // ---- settings extras ----
  gear: (<><circle cx="12" cy="12" r="3.2" /><path d="M12 3.5v2.2M12 18.3v2.2M3.5 12h2.2M18.3 12h2.2M5.8 5.8l1.6 1.6M16.6 16.6l1.6 1.6M18.2 5.8l-1.6 1.6M7.4 16.6l-1.6 1.6" /></>),
  bolt: <path d="M13 3L5 13h5l-1 8 8-10h-5l1-8z" />,
  shield: (<><path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6l7-3z" /><path d="M9 12l2 2 4-4" /></>),
  keyboard: (<><rect x="3" y="6" width="18" height="12" rx="2" /><path d="M7 10h0M11 10h0M15 10h0M7 14h10" stroke-width="2.2" /></>),
  sliders: (<><path d="M5 8h14M5 16h14" /><circle cx="9" cy="8" r="2" fill="var(--bg)" /><circle cx="15" cy="16" r="2" fill="var(--bg)" /></>),
  palette: (<><path d="M12 3a9 9 0 1 0 0 18c1.2 0 2-.8 2-1.8 0-.5-.2-.9-.5-1.2-.3-.3-.5-.7-.5-1.2 0-1 .8-1.8 1.8-1.8H17a4 4 0 0 0 4-4c0-3.9-4-6-9-6z" /><circle cx="7.5" cy="11" r="1" fill="currentColor" stroke="none" /><circle cx="12" cy="8" r="1" fill="currentColor" stroke="none" /><circle cx="16.5" cy="11" r="1" fill="currentColor" stroke="none" /></>),
  info: (<><circle cx="12" cy="12" r="8.5" /><path d="M12 11v5" /><circle cx="12" cy="8" r="0.6" fill="currentColor" stroke="none" /></>),
  cursor: (<><path d="M6 4l13 7-5.5 1.5L11 18 6 4z" /></>),
  grip: (<><circle cx="9" cy="7" r="1.1" fill="currentColor" stroke="none" /><circle cx="15" cy="7" r="1.1" fill="currentColor" stroke="none" /><circle cx="9" cy="12" r="1.1" fill="currentColor" stroke="none" /><circle cx="15" cy="12" r="1.1" fill="currentColor" stroke="none" /><circle cx="9" cy="17" r="1.1" fill="currentColor" stroke="none" /><circle cx="15" cy="17" r="1.1" fill="currentColor" stroke="none" /></>),
  alert: (<><path d="M12 4l9 16H3l9-16z" /><path d="M12 10v4" /><circle cx="12" cy="17" r="0.6" fill="currentColor" stroke="none" /></>),
  link: (<><path d="M9.5 14.5l5-5" /><path d="M8 11l-2 2a3 3 0 0 0 4.2 4.2l2-2" /><path d="M16 13l2-2a3 3 0 0 0-4.2-4.2l-2 2" /></>),
};
Object.assign(window, { LBIcon, LB_ICON_PATHS });
