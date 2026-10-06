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
/// **版式按移动端重排，不是 Web 端 `.notebook-container` 的照搬。**
/// Web 端是「居中卡片 + 2px 边框 + 阴影 + 限宽 900」，那套在手机上：
/// - 边框和留白白吃掉本就不宽的可视区；
/// - 判定区压在输入框下面，键盘一弹就被顶掉。
///
/// 所以这里：**全出血**（无边框无阴影）、顶部压成一条细的对手条、
/// 判定区挪到**输入框上方**（键盘弹起也够得着）、
/// 判定未解锁时只占一条提示的高度（[AnimatedSize] 展开）。
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
    // 发完一条通常要等对方回应，键盘挡着聊天区和判定区，收起来
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickSticker() async {
    // 表情面板也是从底部弹出，先收键盘免得叠在一起
    FocusScope.of(context).unfocus();
    await showTuringStickerSheet(
      context,
      onPick: (Sticker s) {
        widget.client.sendSticker(id: s.id, name: s.displayName, url: s.imageUrl);
      },
    );
    _dropFocusAfterSheet();
  }

  Future<void> _report() async {
    FocusScope.of(context).unfocus();
    final String? reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => _ReportSheet(),
    );
    if (!mounted) return;
    _dropFocusAfterSheet();
    if (reason == null) return;
    // 回执由服务端 report_result 给出，外层统一弹提示
    widget.client.report(reason);
  }

  /// 底部面板关闭后把焦点彻底放掉。
  ///
  /// 面板 pop 时框架会把焦点**还给打开前的那个节点**
  /// （`ModalRoute` 恢复自己的 `_focusedChild`），于是键盘又弹起来 ——
  /// 打开前那次 `unfocus()` 挡不住，因为它只是把焦点移到 scope 上，
  /// `_focusedChild` 仍指着输入框。所以关掉之后必须再收一次。
  void _dropFocusAfterSheet() {
    if (!mounted) return;
    // 焦点恢复发生在 pop 之后（可能晚一帧），所以再等一帧收一次。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });
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

    // 有新消息时贴底
    if (c.feed.length != _lastFeedLength) {
      _lastFeedLength = c.feed.length;
      _scrollToBottomSoon();
    }

    // 全出血：不套卡片。宽屏（平板/横屏）才限宽居中，且只是限宽、不画框。
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: <Widget>[
            _OpponentStrip(client: c, onReport: _report),
            Expanded(
              child: RuledPaper(
                lineHeight: 30,
                lineColor: p.chatGrid,
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  itemCount: c.feed.length,
                  itemBuilder: (BuildContext context, int i) =>
                      TuringBubble(item: c.feed[i]),
                ),
              ),
            ),
            if (c.phase == TuringPhase.chatting)
              _JudgeBar(
                client: c,
                tagController: _tag,
                onJudge: (String guess) {
                  FocusScope.of(context).unfocus();
                  c.judge(guess, tag: _tag.text.trim());
                },
              )
            else if (c.phase == TuringPhase.waitingOpponent)
              const _WaitingBar(),
            _InputBar(
              controller: _input,
              enabled: c.inputEnabled,
              onSend: _send,
              onPickSticker: _pickSticker,
            ),
          ],
        ),
      ),
    );
  }
}

/// 对手条：一条细的横条，取代 Web 端那个大块 `.chat-header`。
///
/// 对局中不暴露对手昵称（`???`），结果页才揭晓。
class _OpponentStrip extends StatelessWidget {
  const _OpponentStrip({required this.client, required this.onReport});

  final TuringClient client;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool urgent = client.remainingSeconds <= 10;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: p.surfaceHeader,
        border: Border(bottom: BorderSide(color: p.borderLighter, width: 2)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: client.connected ? p.success : p.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '对手',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: p.textSubtle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            client.phase == TuringPhase.finished && client.opponentName.isNotEmpty
                ? client.opponentName
                : '???',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: p.inkBlack,
            ),
          ),
          const Spacer(),
          // 计时：对局里最该一眼看到的信息，做成高亮条
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: urgent ? p.dangerLight : p.noteYellow,
              border: Border.all(color: p.inkBlack, width: 2),
              borderRadius: XqfRadii.tag,
            ),
            child: Text(
              client.remainingLabel,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: urgent ? p.dangerDark : p.inkBlue,
              ),
            ),
          ),
          const SizedBox(width: 6),
          HeaderIconButton(
            icon: 'alert',
            tooltip: '举报对方',
            size: 15,
            onPressed: onReport,
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: p.bgInput,
        border: Border(top: BorderSide(color: p.borderLighter, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: DoodleField(
                key: const Key('turing-input'),
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
            const SizedBox(width: 8),
            DoodleButton(
              icon: 'send',
              onPressed: enabled ? onSend : null,
              child: const Text('发送'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 判定区（深色）。
///
/// 未解锁时只占一条提示的高度；解锁后 [AnimatedSize] 展开出两个按钮和标签输入。
/// 放在输入框**上方**，键盘弹起时不会被顶掉。
class _JudgeBar extends StatefulWidget {
  const _JudgeBar({
    required this.client,
    required this.tagController,
    required this.onJudge,
  });

  final TuringClient client;
  final TextEditingController tagController;
  final void Function(String guess) onJudge;

  @override
  State<_JudgeBar> createState() => _JudgeBarState();
}

class _JudgeBarState extends State<_JudgeBar> {
  /// 标签默认折叠。
  ///
  /// 判定区在手机上本来就占地方，而标签是**可选**的次要输入 ——
  /// 常驻一个输入框等于把主要动作（两个判定按钮）往下挤。
  bool _tagOpen = false;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool can = widget.client.canJudge;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        color: p.judgeBg,
        padding: EdgeInsets.fromLTRB(14, can ? 10 : 8, 14, can ? 10 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (can) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _JudgeButton(
                      label: '它是人类',
                      icon: 'user',
                      onTap: () => widget.onJudge('human'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _JudgeButton(
                      label: '它是 AI',
                      icon: 'server',
                      onTap: () => widget.onJudge('ai'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => setState(() => _tagOpen = !_tagOpen),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppIcon(
                          _tagOpen ? 'chevron-down' : 'plus',
                          size: 12,
                          color: p.textAa,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _tagOpen ? '收起标签' : '贴个标签（可选）',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: p.textAa,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_tagOpen) ...<Widget>[
                const SizedBox(height: 4),
                DoodleField(
                  controller: widget.tagController,
                  hint: '给对手贴个标签（10 字内）',
                  maxLength: 10,
                  fontSize: 13,
                ),
              ],
              const SizedBox(height: 4),
            ],
            Text(
              widget.client.judgeHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.4,
                color: can ? p.noteYellow : p.textAa,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JudgeButton extends StatelessWidget {
  const _JudgeButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: p.surfaceWhite, width: 2),
          borderRadius: XqfRadii.button,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppIcon(icon, size: 15, color: p.surfaceWhite),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: p.surfaceWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 已提交判定、等对方时的细条。
class _WaitingBar extends StatelessWidget {
  const _WaitingBar();

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      width: double.infinity,
      color: p.judgeBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Text(
        '已锁定答案，等待对方判定…',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: p.noteYellow,
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
