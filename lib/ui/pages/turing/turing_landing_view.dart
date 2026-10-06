import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../../data/turing/turing_client.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/doodle.dart';
import '../../widgets/paper.dart';

/// 落地页：Hero + 时长选择 + 开始匹配。
///
/// 与 Web 端 `#landing-page` 的差异：
/// - Web 端还提供「无限」时长，但接口契约写的是 `duration(300/600)`，
///   且 Web 自己的 `parseInt(v) || 600` 会把 `0` 变成 `600`（选项形同虚设），
///   所以这里只给真正受支持的 5 / 10 分钟。
/// - 本 App 要求先登录才能开局，未登录时把开始按钮换成登录引导。
class TuringLandingView extends StatefulWidget {
  const TuringLandingView({
    super.key,
    required this.client,
    required this.onRequireLogin,
  });

  final TuringClient client;
  final VoidCallback onRequireLogin;

  @override
  State<TuringLandingView> createState() => _TuringLandingViewState();
}

class _TuringLandingViewState extends State<TuringLandingView> {
  static const List<(int, String)> _durations = <(int, String)>[
    (600, '10 分钟'),
    (300, '5 分钟'),
  ];

  int _duration = 600;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final AppScope scope = AppScope.of(context);
    final bool loggedIn = scope.auth.isLoggedIn;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _Hero(),
              const SizedBox(height: 20),
              if (widget.client.banned) ...<Widget>[
                _BanBanner(message: widget.client.bannedMessage),
                const SizedBox(height: 16),
              ],
              DoodlePanel(
                tone: NoteTone.yellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (!loggedIn) ...<Widget>[
                      Row(
                        children: <Widget>[
                          AppIcon('lock', size: 18, color: p.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '需要登录后才能开始对局',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: p.inkBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '登录后战绩、标签与聊天记录才能归属到你的账号。'
                        '对局本身不需要昵称，系统用你账号里的代号。',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.6,
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DoodleButton(
                        expand: true,
                        icon: 'user',
                        fontSize: 15,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: widget.onRequireLogin,
                        child: const Text('去「我的」登录'),
                      ),
                    ] else ...<Widget>[
                      _OnlineLine(count: widget.client.onlineCount),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Text(
                            '聊多久',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: p.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          for (final (int value, String label) in _durations) ...<Widget>[
                            DoodleChoiceChip(
                              label: label,
                              active: _duration == value,
                              onTap: () => setState(() => _duration = value),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      DoodleButton(
                        expand: true,
                        icon: 'bolt',
                        fontSize: 15,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: widget.client.banned
                            ? null
                            : () => widget.client.start(
                                  nickname: scope.auth.nickname ?? '玩家',
                                  playerToken: scope.auth.token ?? '',
                                  fingerprint: scope.auth.fingerprint,
                                  durationSeconds: _duration,
                                ),
                        child: Text(widget.client.banned ? '已被封禁' : '马上开始匹配'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 封禁横幅。
class _BanBanner extends StatelessWidget {
  const _BanBanner({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.dangerLight,
        border: Border.all(color: p.danger, width: 2),
        borderRadius: XqfRadii.panel,
      ),
      child: Row(
        children: <Widget>[
          AppIcon('alert', size: 18, color: p.dangerDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? '你已被管理员封禁',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.bold,
                color: p.dangerDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return RuledPaper(
      lineHeight: 30,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '# 在线实验 01',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: p.inkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '屏幕那边的家伙，\n真的是人吗？',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 26,
                height: 1.35,
                fontWeight: FontWeight.bold,
                color: p.inkBlack,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '系统会随机连线一个陌生对象。\n你们要在聊天中试探彼此，猜猜对方是人类还是 AI 机器人。',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.7,
                color: p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineLine extends StatelessWidget {
  const _OnlineLine({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          count == null ? '正在获取在线人数…' : '$count 名玩家在线',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: p.inkBlue,
          ),
        ),
      ],
    );
  }
}
