import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/palette.dart';
import '../../../data/models/turing.dart';
import '../../../data/turing/turing_client.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/doodle.dart';
import '../../widgets/doodle_field.dart';
import '../../widgets/paper.dart';
import '../../widgets/toast.dart';

/// 结果页。
///
/// 文案与信息结构对齐 Web 端 `renderResult()`：
/// 结论 + 揭示 + 六项数据 + 可折叠的「更多操作」。
class TuringResultView extends StatefulWidget {
  const TuringResultView({
    super.key,
    required this.client,
    required this.onExit,
  });

  final TuringClient client;

  /// 返回游戏中心（由外层做 Navigator.pop）。
  final VoidCallback onExit;

  @override
  State<TuringResultView> createState() => _TuringResultViewState();
}

class _TuringResultViewState extends State<TuringResultView> {
  final TextEditingController _message = TextEditingController();

  /// 导出图片时抓取这张卡。
  final GlobalKey _cardKey = GlobalKey();

  bool _actionsOpen = false;
  bool _exporting = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String text = _message.text.trim();
    if (text.isEmpty) return;
    widget.client.leaveMessage(text);
    _message.clear();
  }

  /// 把结果卡渲染成 PNG，交给系统分享面板。
  ///
  /// Web 端用 html2canvas；这里用 `RepaintBoundary.toImage`，
  /// 无需把结果页重画一遍，也不依赖 WebView。
  Future<void> _exportImage() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final RenderObject? obj = _cardKey.currentContext?.findRenderObject();
      if (obj is! RenderRepaintBoundary) {
        throw StateError('结果卡尚未渲染完成');
      }
      final ui.Image image = await obj.toImage(pixelRatio: 3);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('图片编码失败');

      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/xqf_turing_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(data.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(path)],
          subject: '图灵测试对局 · XQFGameHub',
          text: '图灵测试对局 · XQFGameHub',
        ),
      );
    } catch (e) {
      if (mounted) showTopToast(context, '导出失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final TuringClient c = widget.client;
    final TuringResult? r = c.result;
    if (r == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: RepaintBoundary(
            key: _cardKey,
            child: DoodlePanel(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: AppIcon(
                      r.isWin ? 'check' : 'close',
                      size: 46,
                      color: r.isWin ? p.successColor : p.dangerColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    r.verdict,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: r.isWin ? p.successColor : p.dangerColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.reveal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.6,
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Row(label: '你的判断', value: r.userGuessLabel),
                  _Row(label: '对方身份', value: r.opponentTruthLabel),
                  if (r.opponentTag.isNotEmpty)
                    _Row(label: '对方标签', value: r.opponentTag, tag: true),
                  _Row(label: '对方猜你是', value: r.opponentGuessLabel),
                  _Row(label: '对话条数', value: '${r.totalMessages} 条'),
                  _Row(label: '用时', value: _duration(r.elapsed)),
                  const SizedBox(height: 16),

                  // ---- 主要动作 ----
                  DoodleButton(
                    expand: true,
                    icon: 'refresh',
                    fontSize: 15,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: c.replay,
                    child: const Text('再来一局'),
                  ),
                  const SizedBox(height: 8),
                  DoodleButton(
                    expand: true,
                    icon: 'arrow-left',
                    onPressed: widget.onExit,
                    child: const Text('返回游戏中心'),
                  ),
                  const SizedBox(height: 8),
                  DoodleButton(
                    expand: true,
                    icon: _actionsOpen ? 'chevron-down' : 'chevron-right',
                    onPressed: () => setState(() => _actionsOpen = !_actionsOpen),
                    child: Text(_actionsOpen ? '收起更多操作' : '更多操作'),
                  ),

                  // ---- 更多操作 ----
                  if (_actionsOpen) ...<Widget>[
                    const SizedBox(height: 12),
                    const DashedDivider(),
                    const SizedBox(height: 12),

                    // 导出为图片
                    DoodleButton(
                      expand: true,
                      icon: 'image',
                      onPressed: _exporting ? null : _exportImage,
                      child: Text(_exporting ? '导出中…' : '导出为图片'),
                    ),
                    const SizedBox(height: 12),

                    // 保存聊天记录
                    DoodleButton(
                      expand: true,
                      icon: 'upload',
                      onPressed: c.savingHistory || c.saveHistoryOk
                          ? null
                          : c.saveHistory,
                      child: Text(
                        c.savingHistory
                            ? '保存中…'
                            : (c.saveHistoryOk ? '聊天记录已保存' : '保存聊天记录'),
                      ),
                    ),
                    if (c.saveHistoryMessage != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        c.saveHistoryMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: c.saveHistoryOk ? p.success : p.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 分享战绩
                    DoodleButton(
                      expand: true,
                      icon: 'megaphone',
                      onPressed: c.shareRecord,
                      child: const Text('分享战绩到聊天室'),
                    ),
                    const SizedBox(height: 12),

                    // 给对方留言
                    Text(
                      '给对手留句话（可选，20 字内）',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: p.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DoodleField(
                            controller: _message,
                            enabled: c.leaveMessageStatus == null,
                            hint: '想对 TA 说…',
                            maxLength: 20,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DoodleButton(
                          compact: true,
                          onPressed: c.sendingLeaveMessage || c.leaveMessageStatus != null
                              ? null
                              : _sendMessage,
                          child: Text(c.sendingLeaveMessage ? '发送中…' : '发送'),
                        ),
                      ],
                    ),
                    if (c.leaveMessageStatus != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        c.leaveMessageStatus!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: p.success,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.tag = false});

  final String label;
  final String value;
  final bool tag;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: p.textSubtle,
              ),
            ),
          ),
          Expanded(
            child: tag
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: DoodleTag(label: value, solid: true),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: p.inkBlack,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

String _duration(Duration d) {
  final int s = d.inSeconds;
  final String m = (s ~/ 60).toString().padLeft(2, '0');
  final String sec = (s % 60).toString().padLeft(2, '0');
  return '$m:$sec';
}

/// 供外层在离开对局前确认。
Future<bool> confirmLeaveTuring(BuildContext context) => showDoodleConfirm(
      context,
      title: '离开对局',
      message: '当前对局会被放弃，确定要离开吗？',
      confirmText: '离开',
      danger: true,
    );
