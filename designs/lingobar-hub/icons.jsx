// icons.jsx — Lingobar 主窗口图标
const LBIcon = ({ name, size = 18, stroke = 1.75, ...rest }) => {
  const common = { width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round", ...rest };
  return <svg {...common}>{LB_ICON_PATHS[name] || null}</svg>;
};
const LB_ICON_PATHS = {
  star: <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" />,
  starFill: <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" fill="currentColor" />,
  clock: (<><circle cx="12" cy="12" r="8.5" /><path d="M12 7.5V12l3 2" /></>),
  gear: (<><circle cx="12" cy="12" r="3.2" /><path d="M12 3.5v2.2M12 18.3v2.2M3.5 12h2.2M18.3 12h2.2M5.8 5.8l1.6 1.6M16.6 16.6l1.6 1.6M18.2 5.8l-1.6 1.6M7.4 16.6l-1.6 1.6" /></>),
  search: (<><circle cx="11" cy="11" r="6.5" /><path d="M20 20l-3.6-3.6" /></>),
  sound: (<><path d="M5 9.5h3l4-3v11l-4-3H5z" /><path d="M16 9c1 1 1 5 0 6" /><path d="M18.5 7c2 2 2 8 0 10" /></>),
  copy: (<><rect x="9" y="9" width="10" height="11" rx="2" /><path d="M5 15V6a2 2 0 0 1 2-2h8" /></>),
  trash: (<><path d="M5 7h14" /><path d="M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" /><path d="M7 7l1 12a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1l1-12" /></>),
  refresh: (<><path d="M4 12a8 8 0 0 1 13.7-5.6L20 8" /><path d="M20 4v4h-4" /><path d="M20 12a8 8 0 0 1-13.7 5.6L4 16" /><path d="M4 20v-4h4" /></>),
  close: (<><path d="M6 6l12 12" /><path d="M18 6L6 18" /></>),
  check: <path d="M5 12.5l4 4 10-10" />,
  alert: (<><path d="M12 8v5" /><circle cx="12" cy="16.5" r=".6" fill="currentColor" stroke="none" /><path d="M12 3l9 16H3z" /></>),
  chevronDown: <path d="M6 9l6 6 6-6" />,
  chevronRight: <path d="M9 6l6 6-6 6" />,
  spark: (<><path d="M12 4v4M12 16v4M4 12h4M16 12h4" /><path d="M7 7l2 2M15 15l2 2M17 7l-2 2M9 15l-2 2" /></>),
  bookmark: <path d="M7 4h10a1 1 0 0 1 1 1v15l-6-4-6 4V5a1 1 0 0 1 1-1z" />,
  grip: (<><circle cx="9" cy="7" r="1.2" fill="currentColor" stroke="none" /><circle cx="9" cy="12" r="1.2" fill="currentColor" stroke="none" /><circle cx="9" cy="17" r="1.2" fill="currentColor" stroke="none" /><circle cx="15" cy="7" r="1.2" fill="currentColor" stroke="none" /><circle cx="15" cy="12" r="1.2" fill="currentColor" stroke="none" /><circle cx="15" cy="17" r="1.2" fill="currentColor" stroke="none" /></>),
  link: (<><path d="M9.5 14.5l5-5" /><path d="M8 11l-2 2a3 3 0 0 0 4.2 4.2l2-2" /><path d="M16 13l2-2a3 3 0 0 0-4.2-4.2l-2 2" /></>),
  translate: (<><path d="M4 6h9" /><path d="M8.5 4v2c0 3.5-2 6-4.5 7.5" /><path d="M6 9.5c1.2 2 3 3.2 5 3.8" /><path d="M13 20l3.5-9 3.5 9" /><path d="M14.2 17h4.6" /></>),
  grammar: (<><path d="M5 7v10M5 7h3M5 17h3M19 7v10M19 7h-3M19 17h-3" /><path d="M9.5 12h5" /></>),
  rewrite: (<><path d="M4 17l9-9 3 3-9 9H4z" /><path d="M14 7l2-2 3 3-2 2" /></>),
  examples: (<><rect x="4" y="5" width="16" height="14" rx="2" /><path d="M8 9h8M8 12h8M8 15h5" /></>),
  sliders: (<><path d="M5 6h14M5 12h14M5 18h14" /><circle cx="9" cy="6" r="2" fill="#1c1e28" /><circle cx="15" cy="12" r="2" fill="#1c1e28" /><circle cx="8" cy="18" r="2" fill="#1c1e28" /></>),
  shield: (<><path d="M12 3l7 3v6c0 4-3 7-7 9-4-2-7-5-7-9V6z" /><path d="M9 12l2 2 4-4" /></>),
  cursor: (<><path d="M6 4l13 7-5.5 1.5L11 18 6 4z" fill="currentColor" stroke="none" /></>),
  bolt: <path d="M13 3L5 13h5l-1 8 8-10h-5l1-8z" />,
};
Object.assign(window, { LBIcon, LB_ICON_PATHS });
