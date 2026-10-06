import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/hub_socket.dart';
import '../../../state/app_state.dart';
import '../../widgets/doodle.dart';
import '../../widgets/toast.dart';

/// 「分享战绩到聊天室」。
///
/// ⚠️ 分享的是**账号的累计战绩**（总场次 / 胜 / 负 / 胜率），不是某一局的结果：
/// 服务端 `ActionHandler::handleShareRecord` 从库里读 `getRecordStats()` 生成卡片
/// （前端不携带任何战绩数据，防伪造），再经 lobby 通道广播到聊天室。
///
/// 所以它属于「我的」页的数据卡旁边 —— 那里展示的正是同一组累计数字；
/// 放在对局结算页会让人以为是分享本局。
///
/// 走游戏通道 `/ws` 的 `share_record`，复用全局 [HubSocket]。
/// 账号页的连接没有绑定过对局（`GameService::getPlayerId` 为空），
/// 所以**必须显式带 `player_token`**，否则服务端回「请先获取恢复码」。
class ShareRecordButton extends StatefulWidget {
  const ShareRecordButton({super.key});

  @override
  State<ShareRecordButton> createState() => _ShareRecordButtonState();
}

class _ShareRecordButtonState extends State<ShareRecordButton> {
  HubSocket? _hub;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hub != null) return;
    final HubSocket hub = AppScope.of(context).services.hub;
    _hub = hub;
    _sub = hub.messages.listen(_onMessage);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onMessage(Map<String, dynamic> msg) {
    if ('${msg['type']}' != 'share_record_status') return;
    if (!mounted) return;
    final bool ok = msg['success'] == true || msg['ok'] == true;
    setState(() => _sending = false);
    showTopToast(
      context,
      '${msg['message'] ?? (ok ? '战绩卡片已分享到聊天室' : '分享失败，请重试')}',
      isError: !ok,
    );
  }

  void _share() {
    final AppScope scope = AppScope.of(context);
    if (!scope.auth.isLoggedIn || _sending) return;
    setState(() => _sending = true);
    final bool sent = scope.services.hub.send(<String, dynamic>{
      'type': 'share_record',
      'player_token': scope.auth.token ?? '',
    });
    if (!sent) {
      setState(() => _sending = false);
      showTopToast(context, '未连接到服务器，请稍后再试', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoodleButton(
      expand: true,
      icon: 'megaphone',
      onPressed: _sending ? null : _share,
      child: Text(_sending ? '分享中…' : '分享战绩到聊天室'),
    );
  }
}
