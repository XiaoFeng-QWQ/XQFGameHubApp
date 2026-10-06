import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 与 Web 端 `style.css` 的 `.icon` 完全一致的线性图标集。
///
/// 网页写法：`fill:none; stroke:currentColor; stroke-width:2.2;
/// stroke-linecap:round; stroke-linejoin:round`，这里用同一批 SVG 路径
/// 通过 `flutter_svg` 渲染，再用 `srcIn` 滤镜着色，保证线条语言一致。
class AppIcons {
  const AppIcons._();

  static const String home =
      '<path d="M3 10l9-7 9 7v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>'
      '<polyline points="9 22 9 13 15 13 15 22"/>';
  static const String gamepad =
      '<rect x="2" y="7" width="20" height="11" rx="5"/>'
      '<path d="M7 10v5"/><path d="M4.5 12.5h5"/>'
      '<circle cx="16" cy="11" r="1"/><circle cx="18.5" cy="13.5" r="1"/>';
  static const String grid =
      '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/>'
      '<rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>';
  static const String user =
      '<circle cx="12" cy="8" r="4"/><path d="M5 20v-2a4 4 0 0 1 4-4h6a4 4 0 0 1 4 4v2"/>';
  static const String sun =
      '<circle cx="12" cy="12" r="5"/><path d="M12 1v2"/><path d="M12 21v2"/><path d="M4.22 4.22l1.42 1.42"/>'
      '<path d="M18.36 18.36l1.42 1.42"/><path d="M1 12h2"/><path d="M21 12h2"/>'
      '<path d="M4.22 19.78l1.42-1.42"/><path d="M18.36 5.64l1.42-1.42"/>';
  static const String moon = '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>';
  static const String chart =
      '<path d="M4 17l5-6 4 3 6-8"/><path d="M3 3v18h18"/>';
  static const String arrowRight =
      '<path d="M5 12h14"/><path d="M13 6l6 6-6 6"/>';
  static const String arrowLeft =
      '<path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/>';
  static const String soup =
      '<path d="M3 12h18a9 9 0 0 1-9 9 9 9 0 0 1-9-9z"/><path d="M8 8c0-1.5 1-2 1-3.5"/>'
      '<path d="M12 8c0-1.5 1-2 1-3.5"/><path d="M16 8c0-1.5 1-2 1-3.5"/>';
  static const String chat =
      '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>';
  static const String cards =
      '<rect x="3" y="5" width="12" height="16" rx="2"/><path d="M8 5V3h11a2 2 0 0 1 2 2v13h-2"/>';
  static const String bolt = '<path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>';
  static const String gomoku =
      '<circle cx="7" cy="7" r="5" fill="#000"/><circle cx="17" cy="7" r="5"/>'
      '<circle cx="12" cy="17" r="5"/><line x1="2" y1="22" x2="9" y2="15"/>';
  static const String go =
      '<circle cx="9" cy="9" r="5" fill="#000"/><circle cx="15" cy="15" r="5"/>';
  static const String users =
      '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>'
      '<path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>';
  static const String chatLines =
      '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>'
      '<path d="M8 9h8"/><path d="M8 13h5"/>';
  static const String heart =
      '<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78'
      'l8.84 8.84 8.84-8.84a5.5 5.5 0 0 0 0-7.78z"/>';
  static const String edit =
      '<path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/>';
  static const String logout =
      '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/>'
      '<line x1="21" y1="12" x2="9" y2="12"/>';
  static const String close =
      '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>';
  static const String chevronDown = '<path d="M6 9l6 6 6-6"/>';
  static const String chevronRight = '<path d="M9 18l6-6-6-6"/>';
  static const String plus = '<path d="M12 5v14"/><path d="M5 12h14"/>';
  static const String mail =
      '<rect x="3" y="5" width="18" height="14" rx="2"/><polyline points="3 7 12 13 21 7"/>';
  static const String lock =
      '<rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>';
  static const String key =
      '<path d="M21 2l-2 2"/><path d="M15.5 7.5l3 3L22 7l-3-3"/>'
      '<path d="M11.39 11.61a5.5 5.5 0 1 0 7.78 7.78 5.5 5.5 0 0 0-7.78-7.78z"/>';
  static const String link =
      '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>'
      '<path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>';
  static const String trash =
      '<polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>'
      '<path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>';
  static const String upload =
      '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/>'
      '<line x1="12" y1="3" x2="12" y2="15"/>';
  static const String tag =
      '<path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/>'
      '<line x1="7" y1="7" x2="7.01" y2="7"/>';
  static const String history =
      '<path d="M3 3v5h5"/><path d="M3.05 13A9 9 0 1 0 6 5.3L3 8"/><path d="M12 7v5l4 2"/>';
  static const String image =
      '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/>'
      '<polyline points="21 15 16 10 5 21"/>';
  static const String imageOff =
      '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/>'
      '<polyline points="21 15 16 10 5 21"/><line x1="2" y1="2" x2="22" y2="22"/>';
  static const String message =
      '<path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9'
      'L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5'
      'a8.48 8.48 0 0 1 8 8v.5z"/>';
  static const String shield =
      '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>';
  static const String refresh =
      '<polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/>'
      '<path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10"/><path d="M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>';
  static const String eye =
      '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>';
  static const String eyeOff =
      '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>'
      '<path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>'
      '<path d="M14.12 14.12a3 3 0 1 1-4.24-4.24"/>'
      '<line x1="1" y1="1" x2="23" y2="23"/>';
  static const String check = '<polyline points="20 6 9 17 4 12"/>';
  static const String info =
      '<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/>'
      '<line x1="12" y1="8" x2="12.01" y2="8"/>';
  static const String alert =
      '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86'
      'a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/>'
      '<line x1="12" y1="17" x2="12.01" y2="17"/>';
  static const String trophy =
      '<path d="M8 21h8"/><path d="M12 17v4"/><path d="M7 4h10v5a5 5 0 0 1-10 0z"/>'
      '<path d="M7 6H4a3 3 0 0 0 3 3"/><path d="M17 6h3a3 3 0 0 1-3 3"/>';
  static const String clock =
      '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>';
  static const String calendar =
      '<rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/>'
      '<line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>';
  static const String hash =
      '<line x1="4" y1="9" x2="20" y2="9"/><line x1="4" y1="15" x2="20" y2="15"/>'
      '<line x1="10" y1="3" x2="8" y2="21"/><line x1="16" y1="3" x2="14" y2="21"/>';
  static const String send =
      '<line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/>';
  static const String server =
      '<rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/>'
      '<line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/>';
  static const String star =
      '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 9.91 8.26 12 2"/>';
  static const String megaphone =
      '<path d="M3 11h2.586a1 1 0 0 1 .707.293l7.414 7.414A.5.5 0 0 0 14.5 18.35V5.65'
      'a.5.5 0 0 0-.793-.357L6.293 12.707a1 1 0 0 1-.707.293H3a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1z"/>'
      '<path d="M16 9.5a4.5 4.5 0 0 1 0 5"/><path d="M19 7a8 8 0 0 1 0 10"/>';
  static const String qr =
      '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/>'
      '<rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h3v3h-3z"/>'
      '<path d="M21 14v3"/><path d="M14 21h3"/><path d="M21 21h.01"/>';

  static const Map<String, String> all = <String, String>{
    'home': home,
    'gamepad': gamepad,
    'grid': grid,
    'user': user,
    'sun': sun,
    'moon': moon,
    'chart': chart,
    'arrow-right': arrowRight,
    'arrow-left': arrowLeft,
    'soup': soup,
    'chat': chat,
    'cards': cards,
    'bolt': bolt,
    'gomoku': gomoku,
    'go': go,
    'users': users,
    'chat-lines': chatLines,
    'heart': heart,
    'edit': edit,
    'logout': logout,
    'close': close,
    'chevron-down': chevronDown,
    'chevron-right': chevronRight,
    'plus': plus,
    'mail': mail,
    'lock': lock,
    'key': key,
    'link': link,
    'trash': trash,
    'upload': upload,
    'tag': tag,
    'history': history,
    'image': image,
    'image-off': imageOff,
    'message': message,
    'shield': shield,
    'refresh': refresh,
    'eye': eye,
    'eye-off': eyeOff,
    'check': check,
    'info': info,
    'alert': alert,
    'trophy': trophy,
    'clock': clock,
    'calendar': calendar,
    'hash': hash,
    'send': send,
    'server': server,
    'star': star,
    'megaphone': megaphone,
    'qr': qr,
  };
}

/// 线性图标控件。默认尺寸 `1.25em`（随字号缩放），描边 2.2，圆头圆角。
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 2.2,
  });

  final String name;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final String body = AppIcons.all[name] ?? AppIcons.info;
    final Color tint = color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final String svg = '<svg viewBox="0 0 24 24" fill="none" stroke="#000000" '
        'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">'
        '$body</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
