// icons.jsx — SF-style line icons, single stroke weight, currentColor, 24 viewBox.
const LBIcon = ({ name, size = 18, stroke = 1.75, ...rest }) => {
  const common = { width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round", ...rest };
  return <svg {...common}>{LB_ICON_PATHS[name] || null}</svg>;
};
const LB_ICON_PATHS = {
  grammar: (<><path d="M5 7v10" /><path d="M5 7h3" /><path d="M5 17h3" /><path d="M19 7v10" /><path d="M19 7h-3" /><path d="M19 17h-3" /><path d="M9.5 12h5" /><circle cx="12" cy="12" r="0.6" fill="currentColor" stroke="none" /></>),
  sound: (<><path d="M5 9.5h3l4-3v11l-4-3H5z" /><path d="M16 9c1 1 1 5 0 6" /><path d="M18.5 7c2 2 2 8 0 10" /></>),
  play: <path d="M8 6l9 6-9 6V6z" fill="currentColor" stroke="none" />,
  copy: (<><rect x="9" y="9" width="10" height="11" rx="2" /><path d="M5 15V6a2 2 0 0 1 2-2h8" /></>),
  star: <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" />,
  close: (<><path d="M6 6l12 12" /><path d="M18 6L6 18" /></>),
  check: <path d="M5 12.5l4 4 10-10" />,
  spark: (<><path d="M12 4v4M12 16v4M4 12h4M16 12h4" /><path d="M7 7l2 2M15 15l2 2M17 7l-2 2M9 15l-2 2" /></>),
  pin: (<><path d="M9 4h6l-1 6 3 3H7l3-3-1-6z" /><path d="M12 16v4" /></>),
  drag: (<><circle cx="9" cy="6" r="1.2" fill="currentColor" stroke="none" /><circle cx="15" cy="6" r="1.2" fill="currentColor" stroke="none" /><circle cx="9" cy="12" r="1.2" fill="currentColor" stroke="none" /><circle cx="15" cy="12" r="1.2" fill="currentColor" stroke="none" /><circle cx="9" cy="18" r="1.2" fill="currentColor" stroke="none" /><circle cx="15" cy="18" r="1.2" fill="currentColor" stroke="none" /></>),
  // structure-view toggle icons
  chart: (<><rect x="3.5" y="9.5" width="5" height="5" rx="1.2" /><rect x="15.5" y="9.5" width="5" height="5" rx="1.2" /><path d="M8.5 12h7" /><path d="M12 14.5c0 2 0 3 0 3" opacity="0" /></>),
  tree: (<><rect x="9" y="3.5" width="6" height="4" rx="1" /><rect x="3.5" y="16.5" width="6" height="4" rx="1" /><rect x="14.5" y="16.5" width="6" height="4" rx="1" /><path d="M12 7.5v4M12 11.5H6.5v5M12 11.5h5.5v5" /></>),
  // toolbar action icons
  tag: (<><path d="M4 12l8-8 7 0 0 7-8 8z" /><circle cx="15.5" cy="8.5" r="1.3" /></>),
  layers: (<><path d="M12 4l8 4-8 4-8-4 8-4z" /><path d="M4 12l8 4 8-4" /><path d="M4 16l8 4 8-4" /></>),
  link2: (<><path d="M9.5 14.5l5-5" /><path d="M8 11l-2 2a3 3 0 0 0 4.2 4.2l2-2" /><path d="M16 13l2-2a3 3 0 0 0-4.2-4.2l-2 2" /></>),
  bulb: (<><path d="M9 17h6" /><path d="M10 20h4" /><path d="M12 3a6 6 0 0 0-3.5 10.9c.5.4.5 1 .5 1.6h6c0-.6 0-1.2.5-1.6A6 6 0 0 0 12 3z" /></>),
  export: (<><path d="M12 3v12" /><path d="M8 7l4-4 4 4" /><path d="M5 14v5a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-5" /></>),
  info: (<><circle cx="12" cy="12" r="8.5" /><path d="M12 11v5" /><circle cx="12" cy="7.8" r="0.6" fill="currentColor" stroke="none" /></>),
};
Object.assign(window, { LBIcon, LB_ICON_PATHS });
