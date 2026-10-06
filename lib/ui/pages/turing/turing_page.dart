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
  const TuringPage({
    super.key,
    required this.onRequireLogin,
    @visibleForTesting this.client,
  });

  /// 未登录时点「去登录」：由外层切到「我的」页签。
  final VoidCallback onRequireLogin;

  /// 测试注入用。为 null 时页面自己建一个（挂在全局 [HubSocket] 上）。
  final TuringClient? client;

  @override
  State<TuringPage> createState() => _TuringPageState();
}

class _TuringPageState extends State<TuringPage> {
  TuringClient? _client;

  /// 退出流程的互斥锁：防止连点返回键叠出多个确认弹窗。
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_client != null) return;
    final TuringClient c =
        widget.client ?? TuringClient(AppScope.of(context).services.hub);
    c.addListener(() => _onClientUpdate(c));
    _client = c;
  }

  /// 分享 / 举报 / 错误都由服务端异步回执，这里弹提示并清空。
  void _onClientUpdate(TuringClient c) {
    final String? share = c.shareRecordMessage;
    final String? report = c.reportResult;
    final String? error = c.lastError;
    if (share == null && report == null && error == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 一次只弹一条，错误优先
      if (error != null) {
        showTopToast(context, error, isError: true);
      } else if (report != null) {
        showTopToast(context, report, isError: !c.reportOk);
      } else if (share != null) {
        showTopToast(context, share, isError: !c.shareRecordOk);
      }
      c.clearError();
      c.clearReportResult();
      c.clearShareRecordMessage();
    });
  }

  @override
  void dispose() {
    // 只销毁自己创建的；注入进来的由调用方负责
    if (widget.client == null) _client?.dispose();
    super.dispose();
  }

  /// 离开玩法页（返回键 / 页头返回 / 结果页「返回游戏中心」都走这里）。
  ///
  /// ⚠️ 收尾必须用 `Navigator.pop()`，**不能用 `maybePop()`**：
  /// `canPop` 依赖 `client.phase`，而 `reset()` 只是把重建排进队列，
  /// 此刻 PopScope 仍是 `canPop: false` —— `maybePop()` 会判定 doNotPop，
  /// 转而回调 `onPopInvokedWithResult(didPop: false)`，又回到本方法，
  /// 于是同步无限递归，主线程卡死（表现为「应用未响应」）。
  Future<void> _handleBack(TuringClient c) async {
    if (_leaving) return;

    if (c.phase != TuringPhase.landing) {
      _leaving = true;
      final bool ok = await confirmLeaveTuring(context);
      if (!ok) {
        _leaving = false;
        return;
      }
      if (!mounted) return;
      c.reset();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// 结果页「返回游戏中心」：对局已结束，不需要二次确认。
  void _exitToHub(TuringClient c) {
    c.reset();
    Navigator.of(context).pop();
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
            onExit: () => _exitToHub(c),
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
