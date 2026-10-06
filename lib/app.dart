import 'package:flutter/material.dart';

import 'core/env.dart';
import 'core/theme/app_theme.dart';
import 'state/app_state.dart';
import 'ui/pages/app_shell.dart';

/// 应用根组件。
///
/// 主题与 Web 端一致：亮色为点阵纸白，暗色为 `#121220` 深空纸；
/// 主题偏好持久化，支持「跟随系统 / 亮色 / 暗色」三态。
class XqfApp extends StatelessWidget {
  const XqfApp({
    super.key,
    required this.services,
    required this.auth,
    required this.theme,
  });

  final AppServices services;
  final AuthController auth;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      auth: auth,
      theme: theme,
      child: ListenableBuilder(
        listenable: theme,
        builder: (BuildContext context, _) {
          return MaterialApp(
            title: XqfEnv.appName,
            debugShowCheckedModeBanner: false,
            theme: XqfTheme.light(),
            darkTheme: XqfTheme.dark(),
            themeMode: theme.mode,
            home: const AppShell(),
            builder: (BuildContext context, Widget? child) {
              // 手机端禁止系统字体放大破坏手绘排版（Web 端也没有这套缩放）。
              final MediaQueryData mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.2,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
