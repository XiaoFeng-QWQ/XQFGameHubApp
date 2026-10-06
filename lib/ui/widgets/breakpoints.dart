/// 响应式断点。竖屏手机为基准，横屏 / 平板自动放宽。
///
/// - [compact]  < 600   竖屏手机（默认形态）
/// - [medium]   600–899 横屏手机 / 小平板
/// - [expanded] >= 900  平板 / 桌面
class XqfBreakpoints {
  const XqfBreakpoints._();

  static const double medium = 600;
  static const double expanded = 900;

  /// 超过这个宽度改用左侧导航栏（横屏时底部栏会挤占本就不多的高度）。
  static const double railThreshold = 720;

  static bool isMedium(double w) => w >= medium;
  static bool isExpanded(double w) => w >= expanded;
  static bool useRail(double w) => w >= railThreshold;

  /// 按宽度给一个合适的网格列数。
  static int columns(double w, {int compact = 2, int medium = 3, int expanded = 4}) {
    if (w >= XqfBreakpoints.expanded) return expanded;
    if (w >= XqfBreakpoints.medium) return medium;
    return compact;
  }

  /// 页面内容最大宽度（超宽屏时居中，避免一行拉到天边）。
  static double contentMaxWidth(double w) => w >= expanded ? 1040 : 960;
}

/// 底部导航 / 侧边导航的一个条目。
class XqfNavItem {
  const XqfNavItem({required this.icon, required this.label});

  final String icon;
  final String label;
}
