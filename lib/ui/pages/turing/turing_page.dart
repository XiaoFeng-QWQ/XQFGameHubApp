import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../../data/models/turing.dart';
import '../../../data/turing/turing_client.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/doodle.dart';
import '../../widgets/paper.dart';
import '../../widgets/toast.dart';
import 'turing_chat_view.dart';
import 'turing_landing_view.dart';
import 'turing_matching_view.dart';
import 'turing_result_view.dart';

/// 图灵测试（1v1）玩法页。
///
/// 按 [TuringPhase] 在落地 / 匹配 / 对局 / 结果之间切换，
/// 复用全局唯一的 WS 连接（见 `HubSocket`）。
class TuringPage extends StatefulWidget {
  const TuringPage({super.key, required this.onRequireLogin});

  /// 未登录时点「去登录」：由外层切到「我的」页签。
  final VoidCallback onRequireLogin;

  @override
  State<TuringPage> createState() => _TuringPageState();
}

class _TuringPageState extends State<TuringPage> {
  TuringClient? _client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_client != null) return;
    final TuringClient c = TuringClient(AppScope.of(context).services.hub);
    c.addListener(() => _onClientUpdate(c));
    _client = c;
  }

  /// 「分享战绩」的结果由服务端异步返回，这里弹提示并清空。
  void _onClientUpdate(TuringClient c) {
    final String? msg = c.shareRecordMessage;
    if (msg == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showTopToast(context, msg, isError: !c.shareRecordOk);
      c.clearShareRecordMessage();
    });
  }

  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }

  Future<void> _handleBack(TuringClient c) async {
    if (c.phase == TuringPhase.landing) {
      Navigator.of(context).maybePop();
      return;
    }
    final bool ok = await confirmLeaveTuring(context);
    if (!ok || !mounted) return;
    c.reset();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final TuringClient? client = _client;
    if (client == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: client,
      builder: (BuildContext context, _) {
        final bool inMatch = client.phase == TuringPhase.chatting ||
            client.phase == TuringPhase.waitingOpponent;

        return PopScope(
          canPop: client.phase == TuringPhase.landing,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) _handleBack(client);
          },
          child: Scaffold(
            backgroundColor: p.paperBg,
            body: DotGridBackground(
              child: Column(
                children: <Widget>[
                  AppHeader(
                    title: '图灵测试（1v1）',
                    titleSize: 17,
                    leading: HeaderIconButton(
                      icon: 'arrow-left',
                      tooltip: '返回',
                      onPressed: () => _handleBack(client),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(child: _body(client)),
                        // 对局中断线：覆盖一层提示，重连成功后自动消失
                        if (inMatch && !client.connected)
                          Positioned.fill(child: _ReconnectOverlay()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(TuringClient c) => switch (c.phase) {
        TuringPhase.landing => TuringLandingView(
            client: c,
            onRequireLogin: () {
              Navigator.of(context).maybePop();
              widget.onRequireLogin();
            },
          ),
        TuringPhase.matching => TuringMatchingView(client: c),
        TuringPhase.chatting ||
        TuringPhase.waitingOpponent =>
          TuringChatView(client: c),
        TuringPhase.finished => TuringResultView(
            client: c,
            onExit: () {
              c.reset();
              Navigator.of(context).maybePop();
            },
          ),
      };
}

/// 断线覆盖层。
class _ReconnectOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return ColoredBox(
      color: p.scrim,
      child: Center(
        child: DoodlePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon('refresh', size: 30, color: p.warn),
              const SizedBox(height: 12),
              Text(
                '连接已断开',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: p.inkBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '正在自动重连，请稍候…',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
