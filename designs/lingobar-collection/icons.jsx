// icons.jsx — SF-style line icons (reused from lingobar-interactions + collection extras).

const LBIcon = ({ name, size = 18, stroke = 1.75, ...rest }) => {
  const common = {
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: stroke,
    strokeLinecap: "round",
    strokeLinejoin: "round",
    ...rest,
  };
  const P = LB_ICON_PATHS[name] || null;
  return <svg {...common}>{P}</svg>;
};

const LB_ICON_PATHS = {
  translate: (
    <>
      <path d="M4 5h7" />
      <path d="M7.5 5c0 4-1.8 7.5-4 9.5" />
      <path d="M5 9.5c1.4 2 3.4 3.4 5.5 4" />
      <path d="M12.5 20l3.5-9 3.5 9" />
      <path d="M13.7 17h4.6" />
    </>
  ),
  grammar: (
    <>
      <path d="M5 7v10" />
      <path d="M5 7h3" />
      <path d="M5 17h3" />
      <path d="M19 7v10" />
      <path d="M19 7h-3" />
      <path d="M19 17h-3" />
      <path d="M9.5 12h5" />
      <circle cx="12" cy="12" r="0.6" fill="currentColor" stroke="none" />
    </>
  ),
  rewrite: (
    <>
      <path d="M4 20h4l9.5-9.5a2 2 0 0 0-2.8-2.8L5 17.2V20z" />
      <path d="M13.5 6.5l4 4" />
    </>
  ),
  examples: (
    <>
      <path d="M5 7h11" />
      <path d="M5 12h14" />
      <path d="M5 17h8" />
    </>
  ),
  star: (
    <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" />
  ),
  starFill: (
    <path d="M12 4.5l2.3 4.7 5.2.8-3.75 3.65.9 5.15L12 16.9l-4.65 2.45.9-5.15L4.5 10l5.2-.8L12 4.5z" fill="currentColor" />
  ),
  sound: (
    <>
      <path d="M5 9.5h3l4-3v11l-4-3H5z" />
      <path d="M16 9c1 1 1 5 0 6" />
      <path d="M18.5 7c2 2 2 8 0 10" />
    </>
  ),
  copy: (
    <>
      <rect x="9" y="9" width="10" height="11" rx="2" />
      <path d="M5 15V6a2 2 0 0 1 2-2h8" />
    </>
  ),
  close: (
    <>
      <path d="M6 6l12 12" />
      <path d="M18 6L6 18" />
    </>
  ),
  arrowRight: <path d="M5 12h14M13 6l6 6-6 6" />,
  plus: (
    <>
      <path d="M12 5v14" />
      <path d="M5 12h14" />
    </>
  ),
  search: (
    <>
      <circle cx="11" cy="11" r="6" />
      <path d="M16 16l4 4" />
    </>
  ),
  check: <path d="M5 12.5l4 4 10-10" />,
  spark: (
    <>
      <path d="M12 4v4M12 16v4M4 12h4M16 12h4" />
      <path d="M7 7l2 2M15 15l2 2M17 7l-2 2M9 15l-2 2" />
    </>
  ),
  play: <path d="M8 6l9 6-9 6V6z" fill="currentColor" stroke="none" />,
  collection: (
    <>
      <path d="M5 6h14" />
      <path d="M5 11h14" />
      <path d="M5 16h9" />
      <path d="M17.5 16.5l1.5 1.5 2.5-3" />
    </>
  ),
  grid: (
    <>
      <rect x="4" y="4" width="7" height="7" rx="1.5" />
      <rect x="13" y="4" width="7" height="7" rx="1.5" />
      <rect x="4" y="13" width="7" height="7" rx="1.5" />
      <rect x="13" y="13" width="7" height="7" rx="1.5" />
    </>
  ),
  // ---- collection extras ----
  // 删除 / 取消收藏
  trash: (
    <>
      <path d="M5 7h14" />
      <path d="M9 7V5h6v2" />
      <path d="M6.5 7l.8 12.5h9.4L17.5 7" />
      <path d="M10 11v5M14 11v5" />
    </>
  ),
  // 时间流
  clock: (
    <>
      <circle cx="12" cy="12" r="7.5" />
      <path d="M12 8v4l3 2" />
    </>
  ),
  // 分组 / 分类（堆叠层）
  layers: (
    <>
      <path d="M12 4l8 4-8 4-8-4 8-4z" />
      <path d="M4 12l8 4 8-4" />
      <path d="M4 16l8 4 8-4" />
    </>
  ),
  // 列表视图
  list: (
    <>
      <path d="M8 6h12" />
      <path d="M8 12h12" />
      <path d="M8 18h12" />
      <circle cx="4.5" cy="6" r="1.1" fill="currentColor" stroke="none" />
      <circle cx="4.5" cy="12" r="1.1" fill="currentColor" stroke="none" />
      <circle cx="4.5" cy="18" r="1.1" fill="currentColor" stroke="none" />
    </>
  ),
  // 来源 / 跳转链接
  link: (
    <>
      <path d="M9.5 14.5l5-5" />
      <path d="M8 11l-2 2a3 3 0 0 0 4.2 4.2l2-2" />
      <path d="M16 13l2-2a3 3 0 0 0-4.2-4.2l-2 2" />
    </>
  ),
  // 详情箭头
  chevronRight: <path d="M9 6l6 6-6 6" />,
  chevronDown: <path d="M6 9l6 6 6-6" />,
};

Object.assign(window, { LBIcon, LB_ICON_PATHS });
