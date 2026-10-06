import 'package:flutter/material.dart';

import '../../../../core/net/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/xqf_time.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/player_message.dart';
import '../../../../state/app_state.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/doodle_field.dart';
import '../../../widgets/fold_section.dart';
import '../../../widgets/toast.dart';

/// 对手留言管理（对应 Web 端「对手留言管理」面板）。
class MessagesPanel extends StatefulWidget {
  const MessagesPanel({super.key, required this.overview});

  final AccountOverview overview;

  @override
  State<MessagesPanel> createState() => _MessagesPanelState();
}

class _MessagesPanelState extends State<MessagesPanel> {
  PlayerMessageBox? _box;
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final AppScope scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final PlayerMessageBox box = await scope.services.account.messages();
      if (!mounted) return;
      setState(() {
        _box = box;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _setAllow(bool value) async {
    final AppScope scope = AppScope.of(context);
    final PlayerMessageBox? box = _box;
    if (box == null) return;
    setState(() {
      _busy = true;
      _box = PlayerMessageBox(messages: box.messages, allowMessages: value);
    });
    try {
      final String msg =
          await scope.services.account.setMessageSettings(allowMessages: value);
      if (mounted) showTopToast(context, msg);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _box = box);
      showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleHidden(PlayerMessage m) async {
    final AppScope scope = AppScope.of(context);
    setState(() => _busy = true);
    try {
      await scope.services.account.hideMessage(messageId: m.id, hidden: !m.hidden);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final PlayerMessageBox? box = _box;

    return DoodlePanel(
      tone: NoteTone.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHead(title: '对手留言管理', titleSize: 15),
          const SizedBox(height: 12),
          if (box != null)
            DoodleCheckbox(
              value: box.allowMessages,
              label: '允许他人留言',
              onChanged: _busy ? null : _setAllow,
            ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: DotBounce()),
            )
          else if (_error != null)
            EmptyTip(text: _error!, isError: true)
          else if (box == null || box.messages.isEmpty)
            const EmptyTip(text: '暂无留言')
          else
            for (final PlayerMessage m in box.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.surfaceWhite,
                    border: Border.all(color: p.inkBlack, width: 2),
                    borderRadius: XqfRadii.input,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    m.from.isEmpty ? '匿名' : m.from,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: p.inkBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  XqfTime.format(m.createdAt, pattern: 'MM-DD HH:mm', fallback: ''),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: p.textSubtle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.text,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.6,
                                color: m.hidden ? p.textAa : p.inkBlack,
                                decoration:
                                    m.hidden ? TextDecoration.lineThrough : null,
                                decorationColor: p.textAa,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      DoodleButton(
                        compact: true,
                        onPressed: _busy ? null : () => _toggleHidden(m),
                        child: Text(m.hidden ? '显示' : '隐藏'),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
