import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/env.dart';
import '../../../core/net/api_exception.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/xqf_time.dart';
import '../../../data/models/account.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/doodle.dart';
import '../../widgets/doodle_field.dart';
import '../../widgets/paper.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/toast.dart';
import '../web_page.dart';

/// 身份卡（对应 Web 端 `.acc-panel--hero`）。
class AccountHero extends StatefulWidget {
  const AccountHero({
    super.key,
    required this.overview,
    required this.onChanged,
    required this.onAvatarUploaded,
    this.avatarVersion = 0,
  });

  final AccountOverview overview;
  final ValueChanged<AccountOverview> onChanged;
  final VoidCallback onAvatarUploaded;
  final int avatarVersion;

  @override
  State<AccountHero> createState() => _AccountHeroState();
}

class _AccountHeroState extends State<AccountHero> {
  bool _uploading = false;

  Future<void> _pickAvatar() async {
    final AppScope scope = AppScope.of(context);
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 92,
    );
    if (file == null) return;

    final List<int> bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) showTopToast(context, '图片大小不能超过 2MB', isError: true);
      return;
    }

    setState(() => _uploading = true);
    try {
      await scope.services.account.uploadAvatar(
        bytes: bytes,
        filename: file.name.isEmpty ? 'avatar.png' : file.name,
      );
      if (!mounted) return;
      widget.onAvatarUploaded();
      showTopToast(context, '头像已更新');
      await _reloadOverview();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } on FileSystemException {
      if (mounted) showTopToast(context, '图片读取失败', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _reloadOverview() async {
    final AppScope scope = AppScope.of(context);
    try {
      final AccountOverview data = await scope.services.account.overview();
      if (mounted) widget.onChanged(data);
    } on ApiException {
      // 静默失败：头像已上传成功，卡片信息下次刷新即可。
    }
  }

  Future<void> _rename() async {
    final AppScope scope = AppScope.of(context);
    if (!widget.overview.canRename) {
      showTopToast(
        context,
        widget.overview.renameHint.isEmpty ? '本月已修改过昵称' : widget.overview.renameHint,
        isError: true,
      );
      return;
    }
    final TextEditingController controller =
        TextEditingController(text: widget.overview.nickname);
    final String? next = await showDialog<String>(
      context: context,
      barrierColor: XqfPalette.of(context).overlayBg,
      builder: (BuildContext ctx) => _RenameDialog(controller: controller),
    );
    controller.dispose();
    if (next == null || next.trim().isEmpty) return;
    if (next.trim() == widget.overview.nickname) return;

    try {
      final String nickname = await scope.services.account.rename(
        next.trim(),
        fp: scope.auth.fingerprint,
      );
      await scope.auth.updateProfile(nickname: nickname);
      if (!mounted) return;
      showTopToast(context, '昵称已修改为：$nickname');
      await _reloadOverview();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final AccountOverview o = widget.overview;
    final List<String> tags = <String>[...o.wornTags];

    return DoodlePanel(
      tone: NoteTone.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ---------- 头像 + 名字 + 元信息 ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: _uploading ? null : _pickAvatar,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    PlayerAvatar(
                      avatarPath: o.avatar,
                      playerId: o.playerId,
                      nickname: o.nickname,
                      size: 72,
                      version: o.lastPlayedAt,
                    ),
                    if (_uploading)
                      const SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 7,
                      children: <Widget>[
                        Text(
                          o.nickname.isEmpty ? '—' : o.nickname,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: p.inkBlack,
                          ),
                        ),
                        if (o.discriminator != null)
                          Text(
                            '#${o.discriminator}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: p.textMuted,
                            ),
                          ),
                      ],
                    ),
                    if (tags.isNotEmpty || o.wornSpecialTags.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: <Widget>[
                          ...tags.map((String t) => DoodleTag(label: t)),
                          ...o.wornSpecialTags.map(
                            (String t) => DoodleTag(label: t, special: true),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 9),
                    _MetaLine(
                      items: <List<String>>[
                        <String>['编号', o.playerId.isEmpty ? '—' : o.playerId],
                        <String>['注册', XqfTime.formatDate(o.createdAt)],
                        <String>['最近', XqfTime.timeAgo(o.lastPlayedAt)],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---------- 战绩三连 ----------
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(value: '${o.stats.totalGames}', label: '总对局'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(value: '${o.stats.winRate}%', label: '胜率'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: o.stats.avgMsgs is int
                      ? '${o.stats.avgMsgs}'
                      : o.stats.avgMsgs.toStringAsFixed(1),
                  label: '场均发言',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---------- 页脚动作 ----------
          DashedDivider(color: p.borderLight),
          const SizedBox(height: 12),
          if (o.renameHint.isNotEmpty)
            Text(
              o.renameHint,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: p.textSubtle,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: <Widget>[
              LinkTextButton(
                label: '公开主页 →',
                onPressed: o.nickname.isEmpty
                    ? null
                    : () => openInAppWeb(
                          context,
                          url: '${XqfEnv.baseUrl}/player/${Uri.encodeComponent(o.nickname)}',
                          title: '${o.nickname} 的公开主页',
                        ),
              ),
              LinkTextButton(
                label: '全服周报 →',
                onPressed: () => openInAppWeb(
                  context,
                  url: '${XqfEnv.baseUrl}/weekly-report',
                  title: '全服周报',
                ),
              ),
              LinkTextButton(
                label: '修改昵称',
                icon: 'edit',
                onPressed: o.canRename ? _rename : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.items});

  final List<List<String>> items;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: items.map((List<String> kv) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              kv[0],
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: p.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                kv[1],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: p.inkBlack,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: p.surfaceWhite,
        border: Border.all(color: p.inkBlack, width: 2),
        borderRadius: XqfRadii.hand,
        boxShadow: XqfShadows.stat(p),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: p.inkBlue,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: p.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatelessWidget {
  const _RenameDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: p.surfaceWhite,
          border: Border.all(color: p.inkBlack, width: 2),
          borderRadius: XqfRadii.panel,
          boxShadow: XqfShadows.panel(p),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppIcon('edit', size: 16, color: p.inkBlue),
                const SizedBox(width: 8),
                Text(
                  '修改昵称',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: p.inkBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DoodleField(
              controller: controller,
              hint: '新昵称（最长 16 字符）',
              maxLength: 16,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(16),
              ],
              fontSize: 14,
            ),
            const SizedBox(height: 10),
            Text(
              '每月仅可修改一次，请谨慎选择。',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: p.textSubtle,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                DoodleButton(
                  compact: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 10),
                DoodleButton(
                  compact: true,
                  variant: DoodleButtonVariant.success,
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
