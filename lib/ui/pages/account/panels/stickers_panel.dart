import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/net/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/sticker.dart';
import '../../../../state/app_state.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/fold_section.dart';
import '../../../widgets/player_avatar.dart';
import '../../../widgets/toast.dart';

/// 表情管理（对应 Web 端「表情管理」面板 + `sticker-manager.js`）。
///
/// 两个标签页：我的表情（`id` 以 `us_` 开头）与默认表情。
/// 上传走 `POST /api/sticker/upload`（JSON + Base64，解码后 ≤ 2MB）。
class StickersPanel extends StatefulWidget {
  const StickersPanel({super.key, required this.overview});

  final AccountOverview overview;

  @override
  State<StickersPanel> createState() => _StickersPanelState();
}

class _StickersPanelState extends State<StickersPanel> {
  StickerSet? _set;
  bool _loading = true;
  String? _error;
  String _tab = 'mine';
  bool _busy = false;
  String _status = '等待上传';

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
      final StickerSet set = await scope.services.account.stickers();
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

  Future<void> _upload() async {
    final AppScope scope = AppScope.of(context);
    final List<XFile> files = await ImagePicker().pickMultiImage(
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (files.isEmpty) return;

    setState(() {
      _busy = true;
      _status = '上传中…';
    });
    int ok = 0;
    String? lastError;
    for (final XFile file in files) {
      try {
        final List<int> bytes = await file.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          lastError = '图片大小不能超过 2MB';
          continue;
        }
        final String ext = _extOf(file.name);
        await scope.services.account.uploadSticker(
          base64Data: base64Encode(bytes),
          fileExt: ext,
        );
        ok++;
      } on ApiException catch (e) {
        lastError = e.message;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = ok > 0 ? '已上传 $ok 个表情' : (lastError ?? '上传失败');
      _tab = 'mine';
    });
    if (ok > 0) {
      showTopToast(context, '已上传 $ok 个表情，等待审核');
    } else if (lastError != null) {
      showTopToast(context, lastError, isError: true);
    }
    await _load();
  }

  static String _extOf(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'png';
    final String ext = name.substring(dot + 1).toLowerCase();
    return const <String>['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext) ? ext : 'png';
  }

  Future<void> _delete(Sticker s) async {
    final AppScope scope = AppScope.of(context);
    final bool ok = await showDoodleConfirm(
      context,
      title: '删除表情',
      message: '确定要删除「${s.displayName}」吗？',
      confirmText: '删除',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await scope.services.account.deleteSticker(s.id);
      if (mounted) showTopToast(context, '已删除');
      await _load();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addToMine(Sticker s) async {
    final AppScope scope = AppScope.of(context);
    setState(() => _busy = true);
    try {
      await scope.services.account.addStickerToMine(s.id);
      if (mounted) showTopToast(context, '已添加到我的表情');
      await _load();
      if (mounted) setState(() => _tab = 'mine');
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final StickerSet? set = _set;
    final List<Sticker> list =
        _tab == 'mine' ? (set?.mine ?? <Sticker>[]) : (set?.defaults ?? <Sticker>[]);

    return DoodlePanel(
      tone: NoteTone.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHead(
            title: '表情管理',
            note: '上传后由管理员审核',
            titleSize: 15,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              DoodleButton(
                compact: true,
                icon: 'plus',
                onPressed: _busy ? null : _upload,
                child: const Text('上传表情'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: p.textSubtle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _TabButton(
                label: '我的表情',
                active: _tab == 'mine',
                onTap: () => setState(() => _tab = 'mine'),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: '默认表情',
                active: _tab == 'default',
                onTap: () => setState(() => _tab = 'default'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: DotBounce()),
            )
          else if (_error != null)
            EmptyTip(text: _error!, isError: true)
          else if (list.isEmpty)
            EmptyTip(
              text: _tab == 'mine' ? '还没有自定义表情，点击「上传表情」添加' : '暂无默认表情',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 92,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (BuildContext c, int i) => _StickerCell(
                sticker: list[i],
                isMineTab: _tab == 'mine',
                busy: _busy,
                onDelete: () => _delete(list[i]),
                onAdd: () => _addToMine(list[i]),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '支持 PNG / JPG / GIF / WebP，单张不超过 2MB；我的表情需通过审核后才能发送。',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.6,
              color: p.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? p.noteYellow : p.surfaceWhite,
          border: Border.all(color: p.inkBlack, width: 2),
          borderRadius: XqfRadii.chip,
          boxShadow: active ? XqfShadows.chip(p) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: p.inkBlack,
          ),
        ),
      ),
    );
  }
}

class _StickerCell extends StatelessWidget {
  const _StickerCell({
    required this.sticker,
    required this.isMineTab,
    required this.busy,
    required this.onDelete,
    required this.onAdd,
  });

  final Sticker sticker;
  final bool isMineTab;
  final bool busy;
  final VoidCallback onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.surfaceWhite,
        border: Border.all(color: p.inkBlack, width: 2),
        borderRadius: XqfRadii.tag,
        boxShadow: <BoxShadow>[
          BoxShadow(color: p.shadowSm, offset: const Offset(2, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                Center(child: StickerImage(url: sticker.imageUrl, size: 56)),
                if (sticker.isPending || sticker.isRejected)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: sticker.isPending ? p.warn : p.danger,
                        borderRadius: XqfRadii.micro,
                      ),
                      child: Text(
                        sticker.isPending ? '审核中' : '已拒绝',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: busy ? null : (isMineTab ? onDelete : onAdd),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: p.inkBlack, width: 1.5),
                borderRadius: XqfRadii.micro,
              ),
              child: Text(
                isMineTab ? '删除' : '添加',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: p.inkBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
