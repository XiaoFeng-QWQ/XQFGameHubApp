import 'package:flutter/material.dart';

import '../../../core/net/api_exception.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/sticker.dart';
import '../../../state/app_state.dart';
import '../app_icon.dart';
import '../doodle.dart';
import '../toast.dart';

/// 对局内表情选择器（底部抽屉）。
///
/// 表情列表复用 HTTP 的 `/api/sticker/list`（App 侧已有实现与模型），
/// 选中后由调用方通过 WS 发 `{type:'sticker', id}`。
/// 这样不必再走 WS 的 `get_stickers` / `stickers_list` 一套缓存协议。
Future<void> showTuringStickerSheet(
  BuildContext context, {
  required void Function(Sticker sticker) onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext ctx) => _StickerSheet(onPick: onPick),
  );
}

class _StickerSheet extends StatefulWidget {
  const _StickerSheet({required this.onPick});

  final void Function(Sticker sticker) onPick;

  @override
  State<_StickerSheet> createState() => _StickerSheetState();
}

class _StickerSheetState extends State<_StickerSheet> {
  StickerSet? _set;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final StickerSet set = await AppScope.of(context).services.account.stickers();
      if (!mounted) return;
      setState(() {
        _set = set;
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

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final List<Sticker> all = <Sticker>[
      ...?_set?.mine.where((Sticker s) => s.isApproved),
      ...?_set?.defaults,
    ];

    return Container(
      decoration: BoxDecoration(
        color: p.paperBg,
        border: Border(top: BorderSide(color: p.inkBlack, width: 2)),
        borderRadius: XqfRadii.sheet,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: p.borderLight,
                  borderRadius: XqfRadii.micro,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Expanded(child: SectionHead(title: '发送表情', titleSize: 15)),
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AppIcon('close', size: 18, color: p.textSubtle),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: <Widget>[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: p.danger,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DoodleButton(
                      compact: true,
                      icon: 'refresh',
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _load();
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              )
            else if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '还没有可用表情，可在「我的 → 表情管理」里添加',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: p.textSubtle,
                  ),
                ),
              )
            else
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 4),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 84,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: all.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Sticker s = all[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).maybePop();
                        widget.onPick(s);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.surfaceWhite,
                          border: Border.all(color: p.inkBlack, width: 2),
                          borderRadius: XqfRadii.window,
                        ),
                        child: Image.network(
                          s.imageUrl ?? '',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => AppIcon(
                            'image-off',
                            size: 22,
                            color: p.textSubtle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 供调用方在表情加载失败时给出统一提示。
void toastStickerFailed(BuildContext context) =>
    showTopToast(context, '表情发送失败，请检查网络', isError: true);
