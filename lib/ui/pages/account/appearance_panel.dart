import 'package:flutter/material.dart';

import '../../../state/app_state.dart';
import '../../widgets/doodle.dart';

/// 「外观」面板：主题三态切换（跟随系统 / 亮色 / 暗色）。
///
/// 刻意放在「我的」页里**登录与否都渲染**的位置（与「关于」入口并列），
/// 而不是收进「账号设置」折叠分组 —— 主题是设备级偏好、不是账号偏好，
/// 未登录时也必须能改。
///
/// 用三态而不是亮/暗二态：`ThemeController` 一直支持 `ThemeMode.system`，
/// 但原先页头那颗按钮只做亮暗翻转，一旦点过就再也回不到「跟随系统」。
class AppearancePanel extends StatelessWidget {
  const AppearancePanel({super.key});

  /// 顺序即展示顺序。
  static const List<(ThemeMode, String)> _options = <(ThemeMode, String)>[
    (ThemeMode.system, '跟随系统'),
    (ThemeMode.light, '亮色'),
    (ThemeMode.dark, '暗色'),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = AppScope.of(context).theme;

    // AppScope 只在实例变化时通知，主题模式切换不会触发它，
    // 所以这里显式监听 ThemeController，选中态才会跟着动。
    return ListenableBuilder(
      listenable: theme,
      builder: (BuildContext context, _) {
        return DoodlePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SectionHead(title: '外观', note: '偏好保存在本机'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final (ThemeMode mode, String label) in _options)
                    DoodleChoiceChip(
                      label: label,
                      active: theme.mode == mode,
                      onTap: () => theme.setMode(mode),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
