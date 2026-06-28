// icons.jsx — 「我的语言地图」图标
const LBIcon = ({ name, size = 18, stroke = 1.75, ...rest }) => {
  const common = { width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round", ...rest };
  return <svg {...common}>{LB_ICON_PATHS[name] || null}</svg>;
};
const LB_ICON_PATHS = {
  galaxy: (<><circle cx="12" cy="12" r="2.2" /><ellipse cx="12" cy="12" rx="9" ry="3.6" /><ellipse cx="12" cy="12" rx="9" ry="3.6" transform="rotate(60 12 12)" /><ellipse cx="12" cy="12" rx="9" ry="3.6" transform="rotate(120 12 12)" /></>),
  grid: (<><rect x="4" y="4" width="7" height="7" rx="1.5" /><rect x="13" y="4" width="7" height="7" rx="1.5" /><rect x="4" y="13" width="7" height="7" rx="1.5" /><rect x="13" y="13" width="7" height="7" rx="1.5" /></>),
  cards: (<><rect x="4" y="6" width="16" height="4" rx="1.5" /><rect x="4" y="13" width="16" height="4" rx="1.5" /></>),
  spark: (<><path d="M12 4v4M12 16v4M4 12h4M16 12h4" /><path d="M7 7l2 2M15 15l2 2M17 7l-2 2M9 15l-2 2" /></>),
  trend: (<><path d="M4 17l5-5 4 3 7-8" /><path d="M20 7v4h-4" /></>),
  arrowRight: (<><path d="M5 12h14" /><path d="M13 6l6 6-6 6" /></>),
  check: <path d="M5 12.5l4 4 10-10" />,
  alert: (<><path d="M12 8v5" /><circle cx="12" cy="16.5" r=".6" fill="currentColor" stroke="none" /><path d="M12 3l9 16H3z" /></>),
  flame: (<><path d="M12 3c1 3 4 4.5 4 8a4 4 0 0 1-8 0c0-1.5.5-2.5 1.2-3.3C9 9 9.5 7 9 5c2 0 3 1 3-2z" /></>),
  star: <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" />,
  eye: (<><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z" /><circle cx="12" cy="12" r="2.6" /></>),
  layers: (<><path d="M12 3l9 5-9 5-9-5 9-5z" /><path d="M3 13l9 5 9-5" /></>),
  close: (<><path d="M6 6l12 12" /><path d="M18 6L6 18" /></>),
  book: (<><path d="M5 5.5A2 2 0 0 1 7 4h11v14H7a2 2 0 0 0-2 2z" /><path d="M5 5.5V20" /></>),
};
Object.assign(window, { LBIcon, LB_ICON_PATHS });
