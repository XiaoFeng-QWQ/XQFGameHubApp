import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/net/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/tags.dart';
import '../../../../state/app_state.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/fold_section.dart';

/// 我的标签（对应 Web 端 `#account-tag-panel`，逻辑对齐 `account.js`
/// 的 `accountRenderTags` / `accountToggleTag` / `saveAccountTags`）。
///
/// 两组标签：
/// - **官方称号**（`special`）—— 可自选佩戴，最多 [MyTags.max] 个，**不占普通名额**
/// - **普通标签**（`tags` 中 `is_special` 为假）—— 最多 [MyTags.max] 个，显示 `×次数`
class TagsPanel extends StatefulWidget {
  const TagsPanel({super.key, required this.overview, required this.onChanged});

  final AccountOverview overview;
  final ValueChanged<AccountOverview> onChanged;

  @override
  State<TagsPanel> createState() => _TagsPanelState();
}

class _TagsPanelState extends State<TagsPanel> {
  MyTags? _tags;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  String _status = '';
  bool _statusError = false;
  Timer? _statusTimer;

  final Set<String> _worn = <String>{};
  final Set<String> _wornSpecial = <String>{};

  @override
  void initState() {
    super.initState();
    _worn.addAll(widget.overview.wornTags);
    _wornSpecial.addAll(widget.overview.wornSpecialTags);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _setStatus(String message, {bool isError = false, bool autoClear = false}) {
    _statusTimer?.cancel();
    setState(() {
      _status = message;
      _statusError = isError;
    });
    if (autoClear) {
      _statusTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _status = '');
      });
    }
  }

  Future<void> _load() async {
    final AppScope scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final MyTags tags = await scope.services.account.myTags();
      if (!mounted) return;
      setState(() {
        _tags = tags;
        _loading = false;
        _worn
          ..clear()
          ..addAll(tags.worn.isEmpty ? widget.overview.wornTags : tags.worn);
        _wornSpecial
          ..clear()
          ..addAll(
            tags.wornSpecial.isEmpty
                ? widget.overview.wornSpecialTags
                : tags.wornSpecial,
          );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// 普通标签与特殊称号各自独立受 `max` 约束（互不占用名额）。
  void _toggle(String name, {required bool special}) {
    final int max = _tags?.max ?? 3;
    final Set<String> target = special ? _wornSpecial : _worn;
    if (target.contains(name)) {
      setState(() {
        target.remove(name);
        _status = '';
        _statusError = false;
      });
      return;
    }
    if (target.length >= max) {
      _setStatus('最多佩戴 $max 个${special ? '称号' : '标签'}', isError: true, autoClear: true);
      return;
    }
    setState(() {
      target.add(name);
      _status = '';
      _statusError = false;
    });
  }

  Future<void> _save() async {
    final AppScope scope = AppScope.of(context);
    setState(() {
      _saving = true;
      _status = '';
      _statusError = false;
    });
    try {
      final WornTagsResult result = await scope.services.account.setWornTags(
        tags: _worn.toList(),
        specialTags: _wornSpecial.toList(),
      );
      if (!mounted) return;
      // 以服务端返回的最终佩戴状态为准
      setState(() {
        _worn
          ..clear()
          ..addAll(result.worn);
        _wornSpecial
          ..clear()
          ..addAll(result.wornSpecial);
      });
      _setStatus(result.message.isEmpty ? '已保存' : result.message);
      await _refreshOverview();
    } on ApiException catch (e) {
      if (mounted) _setStatus(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 保存成功后刷新总览，让身份卡上的佩戴标签同步更新。
  Future<void> _refreshOverview() async {
    final AppScope scope = AppScope.of(context);
    try {
      final AccountOverview data = await scope.services.account.overview();
      widget.onChanged(data);
    } on ApiException {
      // 忽略：保存本身已成功，总览下次进入页面会重新拉取
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final MyTags? tags = _tags;
    final List<PlayerTag> normal = tags?.normalTags ?? const <PlayerTag>[];
    final List<SpecialTag> special = tags?.specialTags ?? const <SpecialTag>[];
    final int max = tags?.max ?? 3;

    return DoodlePanel(
      tone: NoteTone.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHead(title: '我的标签', note: '最多佩戴 $max 个', titleSize: 15),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: DotBounce()),
            )
          else if (_error != null)
            EmptyTip(text: _error!, isError: true)
          else if (tags == null || tags.isEmpty)
            const EmptyTip(text: '还没有标签，去对局里赢取对手的评价吧～')
          else ...<Widget>[
            // ---------- 官方称号 ----------
            if (special.isNotEmpty) ...<Widget>[
              _GroupLabel(
                text: '官方称号',
                hint: '不占普通标签名额',
                color: p.textSubtle,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: special.map((SpecialTag t) {
                  return _TagChip(
                    label: t.icon == null || t.icon!.isEmpty
                        ? t.name
                        : '${t.icon} ${t.name}',
                    selected: _wornSpecial.contains(t.name),
                    special: true,
                    tooltip: _wornSpecial.contains(t.name) ? '点击取消佩戴' : '点击佩戴',
                    onTap: () => _toggle(t.name, special: true),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // ---------- 普通标签 ----------
            _GroupLabel(text: '普通标签', color: p.textSubtle),
            const SizedBox(height: 6),
            if (normal.isEmpty)
              Text(
                '暂无普通标签',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: p.textSubtle,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: normal.map((PlayerTag t) {
                  return _TagChip(
                    label: '${t.name} ×${t.count}',
                    selected: _worn.contains(t.name),
                    tooltip: _worn.contains(t.name) ? '点击取消佩戴' : '点击佩戴',
                    onTap: () => _toggle(t.name, special: false),
                  );
                }).toList(),
              ),
          ],
          if (_status.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _statusError ? p.danger : p.success,
              ),
            ),
          ],
          const SizedBox(height: 14),
          DoodleButton(
            expand: true,
            compact: true,
            onPressed:
                (_saving || _loading || tags == null || tags.isEmpty) ? null : _save,
            child: Text(_saving ? '保存中…' : '保存佩戴'),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.text, required this.color, this.hint});

  final String text;
  final Color color;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 1,
            color: color,
          ),
        ),
        if (hint != null) ...<Widget>[
          const SizedBox(width: 6),
          Text(
            '（$hint）',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.special = false,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool special;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final Color bg = selected ? (special ? p.inkBlue : p.inkBlack) : p.surfaceWhite;
    final Color fg = selected ? p.surfaceWhite : p.inkBlack;
    final Widget chip = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: selected ? bg : p.inkBlack, width: 1.5),
          borderRadius: XqfRadii.tag,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selected) ...<Widget>[
              AppIcon('check', size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: fg),
            ),
          ],
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}
