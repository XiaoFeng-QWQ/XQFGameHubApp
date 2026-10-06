import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/net/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../data/models/account.dart';
import '../../../../state/app_state.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/doodle_field.dart';
import '../../../widgets/toast.dart';

/// 邮箱绑定（对应 Web 端「邮箱绑定」面板）。
///
/// 验证码走 `POST /api/email/send-code` 且 `scene=bind_email`（需登录），
/// 保存走 `POST /api/account/email`。
class EmailPanel extends StatefulWidget {
  const EmailPanel({super.key, required this.overview, required this.onChanged});

  final AccountOverview overview;
  final ValueChanged<AccountOverview> onChanged;

  @override
  State<EmailPanel> createState() => _EmailPanelState();
}

class _EmailPanelState extends State<EmailPanel> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  bool _sending = false;
  bool _saving = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  bool _validEmail(String v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    final AppScope scope = AppScope.of(context);
    final String email = _email.text.trim();
    if (!_validEmail(email)) {
      showTopToast(context, '邮箱格式不正确', isError: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final int cooldown = await scope.services.auth.sendEmailCode(
        email,
        scene: 'bind_email',
      );
      if (!mounted) return;
      _startCooldown(cooldown <= 0 ? 60 : cooldown);
      showTopToast(context, '验证码已发送到 $email');
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _save() async {
    final AppScope scope = AppScope.of(context);
    final String email = _email.text.trim();
    final String code = _code.text.trim();
    if (!_validEmail(email)) {
      showTopToast(context, '邮箱格式不正确', isError: true);
      return;
    }
    if (code.isEmpty) {
      showTopToast(context, '请输入验证码', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final String saved = await scope.services.account.bindEmail(email: email, code: code);
      await scope.auth.updateProfile(email: saved);
      if (!mounted) return;
      showTopToast(context, '邮箱已更新：$saved');
      _email.clear();
      _code.clear();
      try {
        final AccountOverview data = await scope.services.account.overview();
        widget.onChanged(data);
      } on ApiException {
        // 忽略总览刷新失败
      }
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final String? current = widget.overview.email;

    return DoodlePanel(
      tone: NoteTone.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHead(
            title: '邮箱绑定',
            note: '用于登录 / 找回',
            titleSize: 15,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '当前邮箱',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: p.textSubtle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (current == null || current.isEmpty) ? '未绑定' : current,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: p.inkBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: DoodleField(
                  controller: _email,
                  hint: '邮箱，如 you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 128,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              DoodleButton(
                compact: true,
                onPressed: (_sending || _cooldown > 0) ? null : _sendCode,
                child: Text(_cooldown > 0 ? '$_cooldown s' : '获取验证码'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: DoodleField(
                  controller: _code,
                  hint: '6 位验证码',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  maxLength: 6,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              DoodleButton(
                compact: true,
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中…' : '保存邮箱'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '绑定后可用「邮箱 + 验证码」在其他设备登录；更换邮箱需验证新邮箱。',
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
