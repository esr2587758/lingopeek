// icons.jsx — 语法技能树图标
const LBIcon = ({ name, size = 18, stroke = 1.75, ...rest }) => {
  const common = { width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round", ...rest };
  return <svg {...common}>{LB_ICON_PATHS[name] || null}</svg>;
};
const LB_ICON_PATHS = {
  tree: (<><circle cx="12" cy="5" r="2.4" /><circle cx="6" cy="18" r="2.4" /><circle cx="18" cy="18" r="2.4" /><path d="M12 7.4v3.6M12 11l-6 4.6M12 11l6 4.6" /></>),
  lock: (<><rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V8a4 4 0 0 1 8 0v3" /></>),
  check: <path d="M5 12.5l4 4 10-10" />,
  flame: (<><path d="M12 3c1 3 4 4.5 4 8a4 4 0 0 1-8 0c0-1.5.5-2.5 1.2-3.3C9 9 9.5 7 9 5c2 0 3 1 3-2z" /></>),
  spark: (<><path d="M12 4v4M12 16v4M4 12h4M16 12h4" /><path d="M7 7l2 2M15 15l2 2M17 7l-2 2M9 15l-2 2" /></>),
  arrowRight: (<><path d="M5 12h14" /><path d="M13 6l6 6-6 6" /></>),
  close: (<><path d="M6 6l12 12" /><path d="M18 6L6 18" /></>),
  book: (<><path d="M5 5.5A2 2 0 0 1 7 4h11v14H7a2 2 0 0 0-2 2z" /><path d="M5 5.5V20" /></>),
  eye: (<><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z" /><circle cx="12" cy="12" r="2.6" /></>),
  zoomIn: (<><circle cx="11" cy="11" r="6.5" /><path d="M20 20l-3.6-3.6M11 8.5v5M8.5 11h5" /></>),
  zoomOut: (<><circle cx="11" cy="11" r="6.5" /><path d="M20 20l-3.6-3.6M8.5 11h5" /></>),
  target: (<><circle cx="12" cy="12" r="8.5" /><circle cx="12" cy="12" r="4.5" /><circle cx="12" cy="12" r="1" fill="currentColor" stroke="none" /></>),
};
Object.assign(window, { LBIcon, LB_ICON_PATHS });
