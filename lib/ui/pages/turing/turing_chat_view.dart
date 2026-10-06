import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../../data/models/sticker.dart';
import '../../../data/models/turing.dart';
import '../../../data/turing/turing_client.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/doodle.dart';
import '../../widgets/doodle_field.dart';
import '../../widgets/paper.dart';
import '../../widgets/turing/turing_bubble.dart';
import '../../widgets/turing/turing_sticker_sheet.dart';

/// 对局中：聊天 + 判定。
///
/// 对应 Web 端 `#chat-page` 的 `.notebook-container`：
/// 横格纸聊天区、左黄右蓝气泡、底部深色判定区。
/// 已提交判定后只隐藏判定区，输入区保持可见（与 Web 端一致）。
class TuringChatView extends StatefulWidget {
  const TuringChatView({super.key, required this.client});

  final TuringClient client;

  @override
  State<TuringChatView> createState() => _TuringChatViewState();
}

class _TuringChatViewState extends State<TuringChatView> {
  final TextEditingController _input = TextEditingController();
  final TextEditingController _tag = TextEditingController();
  final ScrollController _scroll = ScrollController();
  int _lastFeedLength = 0;

  @override
  void dispose() {
    _input.dispose();
    _tag.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _input.text;
    if (text.trim().isEmpty) return;
    widget.client.sendMessage(text);
    _input.clear();
  }

  Future<void> _pickSticker() async {
    await showTuringStickerSheet(
      context,
      onPick: (Sticker s) {
        widget.client.sendSticker(id: s.id, name: s.displayName, url: s.imageUrl);
      },
    );
  }

  Future<void> _report() async {
    final String? reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => _ReportSheet(),
    );
    if (reason == null || !mounted) return;
    // 回执由服务端 report_result 给出，外层统一弹提示
    widget.client.report(reason);
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final TuringClient c = widget.client;

    // 有新消息时贴底（只在用户本来就在底部附近时更自然，这里简化为始终贴底）
    if (c.feed.length != _lastFeedLength) {
      _lastFeedLength = c.feed.length;
      _scrollToBottomSoon();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: p.surfaceWhite,
              border: Border.all(color: p.inkBlack, width: 2),
              borderRadius: XqfRadii.notebook,
              boxShadow: XqfShadows.soft(p),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                _ChatHeader(client: c, onReport: _report),
                Expanded(
                  child: RuledPaper(
                    lineHeight: 30,
                    lineColor: p.chatGrid,
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      itemCount: c.feed.length,
                      itemBuilder: (BuildContext context, int i) =>
                          TuringBubble(item: c.feed[i]),
                    ),
                  ),
                ),
                _InputBar(
                  controller: _input,
                  enabled: c.inputEnabled,
                  onSend: _send,
                  onPickSticker: _pickSticker,
                ),
                if (c.phase == TuringPhase.chatting)
                  _JudgeBar(
                    client: c,
                    tagController: _tag,
                    onJudge: (String guess) =>
                        c.judge(guess, tag: _tag.text.trim()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 对局头部：对手 / 连接状态 / 计时 / 举报。
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.client, required this.onReport});

  final TuringClient client;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool urgent = client.remainingSeconds <= 10;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.borderLighter, width: 2)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.noteYellow,
              shape: BoxShape.circle,
              border: Border.all(color: p.inkBlack, width: 2),
            ),
            child: Center(child: AppIcon('user', size: 20, color: p.inkBlack)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '当前对手',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: p.textSubtle,
                  ),
                ),
                Text(
                  // 对局中不暴露对手昵称，结束后结果页才揭晓
                  client.phase == TuringPhase.finished
                      ? (client.opponentName.isEmpty ? '???' : client.opponentName)
                      : '???',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: p.inkBlack,
                  ),
                ),
              ],
            ),
          ),
          // 连接状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: p.borderLight, width: 1.5),
              borderRadius: XqfRadii.tag,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: client.connected ? p.success : p.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  client.connected ? '在线' : '重连中',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: p.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          HeaderIconButton(
            icon: 'alert',
            tooltip: '举报对方',
            size: 16,
            onPressed: onReport,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '剩余时间',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: p.textSubtle,
                ),
              ),
              Text(
                formatClock(client.remainingSeconds),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: urgent ? p.danger : p.inkBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 输入区：输入框（内嵌表情按钮）+ 发送。
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onPickSticker,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onPickSticker;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: p.bgInput,
        border: Border(top: BorderSide(color: p.borderLighter, width: 2)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: DoodleField(
              controller: controller,
              enabled: enabled,
              hint: enabled ? '写点什么试探一下…' : '本局已不能发言',
              maxLength: 300,
              fontSize: 14,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              suffix: GestureDetector(
                onTap: enabled ? onPickSticker : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AppIcon(
                    'sticker',
                    size: 18,
                    color: enabled ? p.inkBlue : p.textAa,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DoodleButton(
            icon: 'send',
            onPressed: enabled ? onSend : null,
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }
}

/// 判定区：深色底 + 两个判定按钮 + 可选标签。
class _JudgeBar extends StatelessWidget {
  const _JudgeBar({
    required this.client,
    required this.tagController,
    required this.onJudge,
  });

  final TuringClient client;
  final TextEditingController tagController;
  final void Function(String guess) onJudge;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool can = client.canJudge;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: p.judgeBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        AppIcon('info', size: 15, color: p.surfaceWhite),
                        const SizedBox(width: 6),
                        Text(
                          '锁定你的答案',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: p.surfaceWhite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '选定后就不能反悔咯',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: p.textAa,
                      ),
                    ),
                  ],
                ),
              ),
              _JudgeButton(
                label: '它是人类',
                icon: 'user',
                color: p.successColor,
                enabled: can,
                onTap: () => onJudge('human'),
              ),
              const SizedBox(width: 8),
              _JudgeButton(
                label: '它是 AI',
                icon: 'server',
                color: p.dangerColor,
                enabled: can,
                onTap: () => onJudge('ai'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DoodleField(
            controller: tagController,
            enabled: can,
            hint: '给对手贴个标签（可选）',
            maxLength: 10,
            fontSize: 13,
          ),
          const SizedBox(height: 6),
          Text(
            client.judgeHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: p.textAa,
            ),
          ),
        ],
      ),
    );
  }
}

class _JudgeButton extends StatelessWidget {
  const _JudgeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: p.surfaceWhite, width: 2),
            borderRadius: XqfRadii.button,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(icon, size: 14, color: p.surfaceWhite),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: p.surfaceWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 举报理由选择。
class _ReportSheet extends StatelessWidget {
  static const List<String> _reasons = <String>[
    '辱骂 / 人身攻击',
    '色情或不当内容',
    '广告 / 刷屏',
    '冒充他人',
    '其他违规行为',
  ];

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.paperBg,
        border: Border(top: BorderSide(color: p.inkBlack, width: 2)),
        borderRadius: XqfRadii.sheet,
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SectionHead(title: '举报对方', note: '请选择理由', titleSize: 15),
            const SizedBox(height: 10),
            for (final String r in _reasons)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(r),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: <Widget>[
                      AppIcon('alert', size: 15, color: p.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: p.inkBlack,
                          ),
                        ),
                      ),
                      AppIcon('chevron-right', size: 14, color: p.textAa),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 秒数 → `MM:SS`（负数归零）。
String formatClock(int seconds) {
  final int s = seconds < 0 ? 0 : seconds;
  final String m = (s ~/ 60).toString().padLeft(2, '0');
  final String sec = (s % 60).toString().padLeft(2, '0');
  return '$m:$sec';
}
