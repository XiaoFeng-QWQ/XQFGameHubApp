import 'package:flutter/material.dart';

import '../../../core/env.dart';
import '../../../core/net/api_exception.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/account.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fold_section.dart';
import '../../widgets/toast.dart';
import '../about_page.dart';
import 'account_guest.dart';
import 'account_hero.dart';
import 'appearance_panel.dart';
import 'panels/bindings_panel.dart';
import 'panels/email_panel.dart';
import 'panels/history_panel.dart';
import 'panels/messages_panel.dart';
import 'panels/security_panel.dart';
import 'panels/stickers_panel.dart';
import 'panels/tags_panel.dart';

/// 「我的」页（对应 Web 端 `GET /account`）。
///
/// 结构：页头 → [加载中] / [未登录：邮箱登录 + 找回账号] /
/// [已登录：身份卡 + 内容管理组 + 账号设置组] → 外观 + 关于入口。
/// 手机端把 7 个面板收进两个**默认折叠**的分组，避免一屏滚到底；
/// 宽屏（横屏 / 平板）自动变两栏。
///
/// 「外观」与「关于」刻意放在分组之外：主题是设备级偏好，
/// 未登录时也要能改。
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  AccountOverview? _overview;
  bool _loading = true;
  String? _error;

  /// 头像本地版本号：上传后 +1，用于强制刷新缓存。
  int _avatarVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final AppScope scope = AppScope.of(context);
    if (!scope.auth.isLoggedIn) {
      setState(() {
        _loading = false;
        _overview = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AccountOverview data = await scope.services.account.overview();
      if (!mounted) return;
      setState(() {
        _overview = data;
        _loading = false;
      });
      await scope.auth.updateProfile(
        nickname: data.nickname,
        playerId: data.playerId,
        email: data.email,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        await scope.auth.signOut();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _overview = null;
        });
        showTopToast(context, '登录状态已失效，请重新登录', isError: true);
        return;
      }
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _onAuthChanged() async {
    setState(() {
      _loading = true;
      _overview = null;
      _error = null;
    });
    await _load();
  }

  void _applyOverview(AccountOverview overview) {
    if (!mounted) return;
    setState(() => _overview = overview);
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);

    return Column(
      children: <Widget>[
        AppHeader(title: '我的账号'),
        Expanded(
          child: ListenableBuilder(
            listenable: scope.auth,
            builder: (BuildContext context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_loading)
                          const LoadingBlock(text: '正在读取账号信息…')
                        else if (!scope.auth.isLoggedIn)
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: AccountGuestView(onSignedIn: _onAuthChanged),
                            ),
                          )
                        else if (_error != null)
                          _ErrorBlock(message: _error!, onRetry: _load)
                        else if (_overview != null) ...<Widget>[
                          AccountHero(
                            overview: _overview!,
                            avatarVersion: _avatarVersion,
                            onChanged: _applyOverview,
                            onAvatarUploaded: () =>
                                setState(() => _avatarVersion++),
                          ),
                          const SizedBox(height: 28),
                          CollapsibleGroup(
                            title: '内容管理',
                            note: '标签、表情与对局内容',
                            children: _panelGrid(<Widget>[
                              TagsPanel(
                                overview: _overview!,
                                onChanged: _applyOverview,
                              ),
                              HistoryPanel(overview: _overview!),
                              StickersPanel(overview: _overview!),
                              MessagesPanel(overview: _overview!),
                            ]),
                          ),
                          const SizedBox(height: 22),
                          CollapsibleGroup(
                            title: '账号设置',
                            note: '登录方式与密码安全',
                            children: _panelGrid(<Widget>[
                              BindingsPanel(
                                overview: _overview!,
                                onChanged: _applyOverview,
                              ),
                              EmailPanel(
                                overview: _overview!,
                                onChanged: _applyOverview,
                              ),
                              SecurityPanel(
                                overview: _overview!,
                                onChanged: _applyOverview,
                                onSignedOut: _onAuthChanged,
                              ),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 28),
                        const AppearancePanel(),
                        const SizedBox(height: 22),
                        const _AboutEntry(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 宽屏两栏、窄屏单列。窄屏时直接返回原列表，避免多余嵌套。
  List<Widget> _panelGrid(List<Widget> panels) {
    return <Widget>[
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          if (c.maxWidth < 840) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < panels.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 22),
                  panels[i],
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < panels.length; i += 2) ...<Widget>[
                if (i > 0) const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: panels[i]),
                    const SizedBox(width: 22),
                    Expanded(
                      child: i + 1 < panels.length
                          ? panels[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    ];
  }
}

/// 「关于」入口：页脚内容（备案、协议、赞助）已全部收进关于页。
class _AboutEntry extends StatelessWidget {
  const _AboutEntry();

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return DoodlePanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AboutPage()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: <Widget>[
              AppIcon('info', size: 17, color: p.inkBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '关于 ${XqfEnv.appName}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: p.inkBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '用户协议 · 隐私政策 · 备案信息 · v${XqfEnv.version}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: p.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon('chevron-right', size: 15, color: p.textAa),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return DoodlePanel(
      tone: NoteTone.pink,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.6,
              color: XqfPalette.of(context).inkBlack,
            ),
          ),
          const SizedBox(height: 16),
          DoodleButton.label(
            label: '重新加载',
            icon: 'refresh',
            expand: true,
            onPressed: () => onRetry(),
          ),
        ],
      ),
    );
  }
}
