// icons.jsx — line icons for grammar-viz.
const LBIcon = ({ name, size = 18, stroke = 1.75, ...rest }) => {
  const common = { width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round", ...rest };
  return <svg {...common}>{LB_ICON_PATHS[name] || null}</svg>;
};
const LB_ICON_PATHS = {
  grammar: (<><path d="M5 7v10" /><path d="M5 7h3" /><path d="M5 17h3" /><path d="M19 7v10" /><path d="M19 7h-3" /><path d="M19 17h-3" /><path d="M9.5 12h5" /><circle cx="12" cy="12" r="0.6" fill="currentColor" stroke="none" /></>),
  sound: (<><path d="M5 9.5h3l4-3v11l-4-3H5z" /><path d="M16 9c1 1 1 5 0 6" /><path d="M18.5 7c2 2 2 8 0 10" /></>),
  copy: (<><rect x="9" y="9" width="10" height="11" rx="2" /><path d="M5 15V6a2 2 0 0 1 2-2h8" /></>),
  star: <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" />,
  close: (<><path d="M6 6l12 12" /><path d="M18 6L6 18" /></>),
  check: <path d="M5 12.5l4 4 10-10" />,
  spark: (<><path d="M12 4v4M12 16v4M4 12h4M16 12h4" /><path d="M7 7l2 2M15 15l2 2M17 7l-2 2M9 15l-2 2" /></>),
  play: <path d="M8 6l9 6-9 6V6z" fill="currentColor" stroke="none" />,
  highlight: (<><path d="M4 20h16" /><path d="M6 16l8-8 4 4-8 8H6v-4z" /></>),
  arc: (<><path d="M4 16c2-7 14-7 16 0" /><circle cx="4" cy="16" r="1.4" fill="currentColor" stroke="none" /><circle cx="20" cy="16" r="1.4" fill="currentColor" stroke="none" /></>),
  tree: (<><rect x="9" y="3.5" width="6" height="4" rx="1" /><rect x="3.5" y="16.5" width="6" height="4" rx="1" /><rect x="14.5" y="16.5" width="6" height="4" rx="1" /><path d="M12 7.5v4M12 11.5H6.5v5M12 11.5h5.5v5" /></>),
  trunk: (<><path d="M12 21V8" /><path d="M12 8l-4-3M12 11l4-3" /><circle cx="12" cy="5" r="2" /></>),
  link2: (<><path d="M9.5 14.5l5-5" /><path d="M8 11l-2 2a3 3 0 0 0 4.2 4.2l2-2" /><path d="M16 13l2-2a3 3 0 0 0-4.2-4.2l-2 2" /></>),
  book: (<><path d="M5 5.5A2 2 0 0 1 7 4h11v14H7a2 2 0 0 0-2 2z" /><path d="M5 5.5V20" /></>),
  bulb: (<><path d="M9 17h6" /><path d="M10 20h4" /><path d="M12 3a6 6 0 0 0-3.5 10.9c.5.4.5 1 .5 1.6h6c0-.6 0-1.2.5-1.6A6 6 0 0 0 12 3z" /></>),
};
Object.assign(window, { LBIcon, LB_ICON_PATHS });
