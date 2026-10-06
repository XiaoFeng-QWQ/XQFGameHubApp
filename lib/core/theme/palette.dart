import 'package:flutter/material.dart';

/// XQFGameHub 设计变量。
///
/// 严格对齐 Web 端 `Public/style.css` 的 CSS 变量表（`:root` 与
/// `[data-theme="dark"]`），保证 App 与网页是同一套视觉语言：
/// 2px 手绘描边 + 不规则圆角 + 错位实心阴影 + 便签底色 + 点阵纸背景。
@immutable
class XqfPalette {
  const XqfPalette({
    required this.inkBlack,
    required this.inkBlue,
    required this.paperBg,
    required this.noteYellow,
    required this.notePink,
    required this.noteBlue,
    required this.noteGreen,
    required this.highlighter,
    required this.surfaceWhite,
    required this.surfaceHeader,
    required this.textSecondary,
    required this.textMuted,
    required this.textSubtle,
    required this.textAa,
    required this.borderLight,
    required this.borderLighter,
    required this.bgClipboard,
    required this.bgInput,
    required this.dotColor,
    required this.chatGrid,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.overlayBg,
    required this.danger,
    required this.dangerLight,
    required this.dangerDark,
    required this.success,
    required this.warn,
    required this.badgeChattingBg,
    required this.badgeChattingText,
    required this.badgeJudgingBg,
    required this.badgeJudgingText,
    required this.badgeFinishedBg,
    required this.badgeFinishedText,
    required this.roomWarnBg,
    required this.roomWarnBorder,
    required this.successColor,
    required this.dangerColor,
    required this.coverBg,
    required this.judgeBg,
    required this.scrim,
  });

  // ---- 墨色 ----
  final Color inkBlack;
  final Color inkBlue;

  // ---- 纸面 ----
  final Color paperBg;
  final Color noteYellow;
  final Color notePink;
  final Color noteBlue;
  final Color noteGreen;
  final Color highlighter;
  final Color surfaceWhite;
  final Color surfaceHeader;

  // ---- 文字层级 ----
  final Color textSecondary;
  final Color textMuted;
  final Color textSubtle;
  final Color textAa;

  // ---- 线条 ----
  final Color borderLight;
  final Color borderLighter;

  // ---- 特殊底 ----
  final Color bgClipboard;
  final Color bgInput;
  final Color dotColor;
  final Color chatGrid;

  // ---- 阴影 ----
  final Color shadowSm;
  final Color shadowMd;
  final Color shadowLg;
  final Color overlayBg;

  // ---- 语义色 ----
  final Color danger;
  final Color dangerLight;
  final Color dangerDark;
  final Color success;
  final Color warn;

  // ---- 状态徽标 ----
  final Color badgeChattingBg;
  final Color badgeChattingText;
  final Color badgeJudgingBg;
  final Color badgeJudgingText;
  final Color badgeFinishedBg;
  final Color badgeFinishedText;

  final Color roomWarnBg;
  final Color roomWarnBorder;
  final Color successColor;
  final Color dangerColor;
  final Color coverBg;
  final Color judgeBg;

  /// 图片 / 头像上的半透明遮罩（对应 CSS 的 `rgba(0,0,0,.45)`）。
  final Color scrim;

  bool get isDark => identical(this, dark) || paperBg == dark.paperBg;

  static const XqfPalette light = XqfPalette(
    inkBlack: Color(0xFF2B2B2B),
    inkBlue: Color(0xFF1E3799),
    paperBg: Color(0xFFF8F9FA),
    noteYellow: Color(0xFFFDF5C9),
    notePink: Color(0xFFFDE2E4),
    noteBlue: Color(0xFFD3E2ED),
    noteGreen: Color(0xFFD1F2D3),
    highlighter: Color(0x99FFEB3B),
    surfaceWhite: Color(0xFFFFFFFF),
    surfaceHeader: Color(0xBFFFFFFF),
    textSecondary: Color(0xFF555555),
    textMuted: Color(0xFF666666),
    textSubtle: Color(0xFF888888),
    textAa: Color(0xFFAAAAAA),
    borderLight: Color(0xFFCCCCCC),
    borderLighter: Color(0xFFEEEEEE),
    bgClipboard: Color(0xFFE4CFA1),
    bgInput: Color(0xFFFAFAFA),
    dotColor: Color(0xFFD1D1D1),
    chatGrid: Color(0xFFE1E9F0),
    shadowSm: Color(0x0D000000),
    shadowMd: Color(0x1A000000),
    shadowLg: Color(0x26000000),
    overlayBg: Color(0x66FFFFFF),
    danger: Color(0xFFE74C3C),
    dangerLight: Color(0xFFFDE2E4),
    dangerDark: Color(0xFFC62828),
    success: Color(0xFF27AE60),
    warn: Color(0xFFF39C12),
    badgeChattingBg: Color(0xFFD1F2D3),
    badgeChattingText: Color(0xFF2E7D32),
    badgeJudgingBg: Color(0xFFFDF5C9),
    badgeJudgingText: Color(0xFFF9A825),
    badgeFinishedBg: Color(0xFFE0E0E0),
    badgeFinishedText: Color(0xFF666666),
    roomWarnBg: Color(0xFFFFF0F0),
    roomWarnBorder: Color(0xFFE74C3C),
    successColor: Color(0xFF4CAF50),
    dangerColor: Color(0xFFF44336),
    coverBg: Color(0x0D000000),
    judgeBg: Color(0xFF2B2B2B),
    scrim: Color(0x73000000),
  );

  static const XqfPalette dark = XqfPalette(
    inkBlack: Color(0xFFE0E0E0),
    inkBlue: Color(0xFF7AA2F7),
    paperBg: Color(0xFF121220),
    noteYellow: Color(0xFF3A3A20),
    notePink: Color(0xFF3A2530),
    noteBlue: Color(0xFF253040),
    noteGreen: Color(0xFF253A2A),
    highlighter: Color(0x26FFEB3B),
    surfaceWhite: Color(0xFF1E1E32),
    surfaceHeader: Color(0xD91E1E32),
    textSecondary: Color(0xFFBBBBBB),
    textMuted: Color(0xFF999999),
    textSubtle: Color(0xFF888888),
    textAa: Color(0xFF666666),
    borderLight: Color(0xFF444444),
    borderLighter: Color(0xFF333333),
    bgClipboard: Color(0xFF2A2A48),
    bgInput: Color(0xFF1E1E32),
    dotColor: Color(0xFF2A2A40),
    chatGrid: Color(0xFF2A2A40),
    shadowSm: Color(0x33000000),
    shadowMd: Color(0x4D000000),
    shadowLg: Color(0x66000000),
    overlayBg: Color(0x80000000),
    danger: Color(0xFFE74C3C),
    dangerLight: Color(0xFFFDE2E4),
    dangerDark: Color(0xFFC62828),
    success: Color(0xFF27AE60),
    warn: Color(0xFFF39C12),
    badgeChattingBg: Color(0xFF253A2A),
    badgeChattingText: Color(0xFF81C784),
    badgeJudgingBg: Color(0xFF3A3A20),
    badgeJudgingText: Color(0xFFFFCA28),
    badgeFinishedBg: Color(0xFF2A2A40),
    badgeFinishedText: Color(0xFF888888),
    roomWarnBg: Color(0xFF3A2525),
    roomWarnBorder: Color(0xFFE74C3C),
    successColor: Color(0xFF81C784),
    dangerColor: Color(0xFFE57373),
    coverBg: Color(0x0DFFFFFF),
    judgeBg: Color(0xFF0F0F1A),
    scrim: Color(0x73000000),
  );

  static XqfPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// 手绘不规则圆角。数值与 Web 端 `border-radius: a b c d / e f g h` 一一对应。
class XqfRadii {
  const XqfRadii._();

  /// `.hub-hand` / `.doodle-border` / `.acc-stat`
  static const BorderRadius hand = BorderRadius.only(
    topLeft: Radius.elliptical(255, 15),
    topRight: Radius.elliptical(15, 225),
    bottomRight: Radius.elliptical(225, 15),
    bottomLeft: Radius.elliptical(15, 255),
  );

  /// `.doodle-btn`
  static const BorderRadius button = BorderRadius.only(
    topLeft: Radius.elliptical(10, 255),
    topRight: Radius.elliptical(255, 15),
    bottomRight: Radius.elliptical(15, 225),
    bottomLeft: Radius.elliptical(225, 15),
  );

  /// `.acc-panel`
  static const BorderRadius panel = BorderRadius.only(
    topLeft: Radius.elliptical(20, 6),
    topRight: Radius.elliptical(6, 20),
    bottomRight: Radius.elliptical(20, 6),
    bottomLeft: Radius.elliptical(6, 20),
  );

  /// `.hub-nav-chip` / `.hub-filter` / `.hub-ticket-strip` / `.hub-hero-marquee`
  static const BorderRadius chip = BorderRadius.only(
    topLeft: Radius.elliptical(14, 4),
    topRight: Radius.elliptical(4, 14),
    bottomRight: Radius.elliptical(14, 4),
    bottomLeft: Radius.elliptical(4, 14),
  );

  /// `.hub-card-window`
  static const BorderRadius window = BorderRadius.only(
    topLeft: Radius.elliptical(12, 3),
    topRight: Radius.elliptical(3, 12),
    bottomRight: Radius.elliptical(12, 3),
    bottomLeft: Radius.elliptical(3, 12),
  );

  /// `.input-line input` / `.oauth-bind-row`
  static const BorderRadius input = BorderRadius.only(
    topLeft: Radius.elliptical(8, 3),
    topRight: Radius.elliptical(3, 8),
    bottomRight: Radius.elliptical(8, 3),
    bottomLeft: Radius.elliptical(3, 8),
  );

  /// `.acc-tag` / `.hub-card-meta span`
  static const BorderRadius tag = BorderRadius.only(
    topLeft: Radius.elliptical(10, 3),
    topRight: Radius.elliptical(3, 10),
    bottomRight: Radius.elliptical(10, 3),
    bottomLeft: Radius.elliptical(3, 10),
  );

  /// `.hub-stamp`
  static const BorderRadius stamp = BorderRadius.all(Radius.circular(4));

  /// 底部抽屉（聊天记录详情）顶部圆角。
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(18));

  /// 极小的角标 / 小药丸（审核状态、拖拽把手）。
  static const BorderRadius micro = BorderRadius.all(Radius.circular(3));

  /// 纯圆（头像、圆形返回键）
  static const BorderRadius circle = BorderRadius.all(Radius.circular(999));

  // ---- 玩法内页（图灵测试）----

  /// 对手气泡（Web 端 `.bubble-left`：`15px 15px 15px 0`，缺口在左下）。
  static const BorderRadius bubbleLeft = BorderRadius.only(
    topLeft: Radius.circular(15),
    topRight: Radius.circular(15),
    bottomRight: Radius.circular(15),
  );

  /// 自己气泡（Web 端 `.bubble-right`：`15px 15px 0 15px`，缺口在右下）。
  static const BorderRadius bubbleRight = BorderRadius.only(
    topLeft: Radius.circular(15),
    topRight: Radius.circular(15),
    bottomLeft: Radius.circular(15),
  );
}

/// 错位实心阴影（Web 端 `box-shadow: Xpx Ypx 0 var(--shadow-*)`）。
class XqfShadows {
  const XqfShadows._();

  static List<BoxShadow> hard(Color color, Offset offset) => <BoxShadow>[
        BoxShadow(color: color, offset: offset, blurRadius: 0, spreadRadius: 0),
      ];

  /// `.acc-panel` / `.doodle-border`
  static List<BoxShadow> panel(XqfPalette p) => hard(p.shadowMd, const Offset(4, 6));

  /// `.hub-card`
  static List<BoxShadow> card(XqfPalette p) => hard(p.shadowSm, const Offset(2, 4));

  /// `.hub-nav-chip` / `.hub-box`
  static List<BoxShadow> chip(XqfPalette p) => hard(p.shadowMd, const Offset(2, 2));

  /// `.acc-stat`
  static List<BoxShadow> stat(XqfPalette p) => hard(p.shadowMd, const Offset(3, 4));

  /// `.hub-card-window`
  static List<BoxShadow> window(XqfPalette p) => hard(p.shadowMd, const Offset(2, 2));

  /// 柔和大阴影（.sticky-hero 等）
  static List<BoxShadow> soft(XqfPalette p) => <BoxShadow>[
        BoxShadow(color: p.shadowMd, offset: const Offset(3, 5), blurRadius: 10),
      ];
}

/// 字距 / 间距等排版常量，对齐 Web 端常用值。
class XqfSpacing {
  const XqfSpacing._();

  static const double pageMaxWidth = 720;
  static const double pagePadding = 16;
  static const double panelGap = 22;
  static const double groupGap = 26;
}
