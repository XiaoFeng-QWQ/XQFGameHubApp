import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../state/app_state.dart';
import '../widgets/app_icon.dart';
import '../widgets/breakpoints.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/paper.dart';
import 'account/account_page.dart';
import 'games_page.dart';
import 'home_page.dart';

/// App 外壳：底部导航（竖屏）/ 左侧导航（横屏与平板）+ 页面栈。
///
/// 之前「我的账号」藏在首页右上角的小 chip 里，是网页顶栏的思路；
/// 现在改为标准 App 的主导航，三个页签分别是首页 / 玩法 / 我的。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const List<XqfNavItem> _items = <XqfNavItem>[
    XqfNavItem(icon: 'home', label: '首页'),
    XqfNavItem(icon: 'gamepad', label: '玩法'),
    XqfNavItem(icon: 'user', label: '我的'),
  ];

  int _index = 0;

  /// 惰性构建：没访问过的页签不实例化，避免启动时就发请求。
  final Set<int> _visited = <int>{0};

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final ThemeController theme = AppScope.of(context).theme;

    return ListenableBuilder(
      listenable: theme,
      builder: (BuildContext context, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        void toggleTheme() => theme.toggle(Theme.of(context).brightness);

        final List<Widget> pages = <Widget>[
          HomePage(onOpenGames: () => _select(1), onToggleTheme: toggleTheme, isDark: isDark),
          GamesPage(onToggleTheme: toggleTheme, isDark: isDark),
          AccountPage(onToggleTheme: toggleTheme, isDark: isDark),
        ];

        return PopScope(
          // 不在首页时，返回键先回到首页，而不是直接退出 App
          canPop: _index == 0,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) _select(0);
          },
          child: Scaffold(
            backgroundColor: p.paperBg,
            body: DotGridBackground(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final Widget stack = IndexedStack(
                    index: _index,
                    children: List<Widget>.generate(
                      pages.length,
                      (int i) => _visited.contains(i)
                          ? pages[i]
                          : const SizedBox.shrink(),
                    ),
                  );

                  if (XqfBreakpoints.useRail(c.maxWidth)) {
                    return Row(
                      children: <Widget>[
                        XqfNavRail(
                          items: _items,
                          index: _index,
                          onChanged: _select,
                          header: AppIcon('grid', size: 26, color: p.inkBlue),
                        ),
                        Expanded(child: stack),
                      ],
                    );
                  }

                  return Column(
                    children: <Widget>[
                      Expanded(child: stack),
                      XqfBottomBar(
                        items: _items,
                        index: _index,
                        onChanged: _select,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
