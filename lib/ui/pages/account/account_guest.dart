import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/env.dart';
import '../../../core/net/api_exception.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/oauth.dart';
import '../../../state/app_state.dart';
import '../../widgets/doodle.dart';
import '../../widgets/doodle_field.dart';
import '../../widgets/fold_section.dart';
import '../../widgets/toast.dart';
import '../web_page.dart';

/// 未登录视图（对应 Web 端 `#account-guest`）。
///
/// 手机端把「邮箱登录 / 注册」「找回账号」两块改为上下堆叠。
/// 第三方 OAuth 登录需要浏览器回调，App 内无法完成，改为引导去网页版。
class AccountGuestView extends StatefulWidget {
  const AccountGuestView({super.key, required this.onSignedIn});

  final Future<void> Function() onSignedIn;

  @override
  State<AccountGuestView> createState() => _AccountGuestViewState();
}

class _AccountGuestViewState extends State<AccountGuestView> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _recoverNickname = TextEditingController();
  final TextEditingController _recoverPassword = TextEditingController();

  bool _sending = false;
  bool _submitting = false;
  bool _recovering = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _email.dispose();
    _code.dispose();
    _recoverNickname.dispose();
    _recoverPassword.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  bool _validEmail(String v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());

  Future<void> _sendCode() async {
    final String email = _email.text.trim();
    if (!_validEmail(email)) {
      showTopToast(context, '邮箱格式不正确', isError: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final int cooldown = await AppScope.of(context).services.auth.sendEmailCode(email);
      if (!mounted) return;
      _startCooldown(cooldown <= 0 ? 60 : cooldown);
      showTopToast(context, '验证码已发送，请查收邮箱');
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
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
    setState(() => _submitting = true);
    try {
      final EmailAuthResult result = await scope.services.auth.emailAuth(
        email: email,
        code: code,
        fp: scope.auth.fingerprint,
      );
      await scope.auth.signIn(
        token: result.token,
        nickname: result.nickname,
        playerId: result.playerId,
        email: result.email ?? email,
      );
      if (!mounted) return;
      showTopToast(
        context,
        result.isNew ? '账号已创建：${result.nickname}' : '登录成功',
      );
      await widget.onSignedIn();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _recover() async {
    final AppScope scope = AppScope.of(context);
    final String nickname = _recoverNickname.text.trim();
    final String password = _recoverPassword.text;
    if (nickname.isEmpty) {
      showTopToast(context, '请先填写代号', isError: true);
      return;
    }
    if (password.isEmpty) {
      showTopToast(context, '请先填写密码', isError: true);
      return;
    }
    setState(() => _recovering = true);
    try {
      final EmailAuthResult result = await scope.services.auth.recover(
        nickname: nickname,
        password: password,
      );
      await scope.auth.signIn(
        token: result.token,
        nickname: result.nickname,
        playerId: result.playerId,
      );
      if (!mounted) return;
      showTopToast(context, '身份已恢复：${result.nickname}');
      await widget.onSignedIn();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ---------- 邮箱登录 / 注册 ----------
        DoodlePanel(
          tone: NoteTone.yellow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SectionHead(
                title: '邮箱登录 / 注册',
                note: '新邮箱自动创建账号',
                titleSize: 15,
              ),
              const SizedBox(height: 14),
              DoodleField(
                controller: _email,
                hint: '邮箱，如 you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                maxLength: 128,
                fontSize: 14,
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
                      autofillHints: const <String>[AutofillHints.oneTimeCode],
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
              const SizedBox(height: 14),
              DoodleButton(
                expand: true,
                icon: 'mail',
                fontSize: 15,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '登录中…' : '登录 / 注册'),
              ),
              const SizedBox(height: 12),
              Text(
                '未注册的邮箱会自动创建账号，昵称由邮箱前缀生成（如 q1432777209_a1b2）。',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                  color: p.textSubtle,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    '注册即代表同意 ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: p.textSecondary,
                    ),
                  ),
                  LinkTextButton(
                    label: '《用户协议》',
                    onPressed: () => openInAppWeb(
                      context,
                      url: XqfEnv.agreementUrl,
                      title: '用户协议',
                    ),
                  ),
                  Text(
                    ' 与 ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: p.textSecondary,
                    ),
                  ),
                  LinkTextButton(
                    label: '《隐私政策》',
                    onPressed: () => openInAppWeb(
                      context,
                      url: XqfEnv.privacyUrl,
                      title: '隐私政策',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ---------- 找回账号 ----------
        DoodlePanel(
          tone: NoteTone.yellow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SectionHead(
                title: '找回账号',
                note: '旧版账号专用',
                titleSize: 15,
              ),
              const SizedBox(height: 12),
              FoldSection(
                title: '已有旧账号？输入代号 + 密码找回',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DoodleField(
                      controller: _recoverNickname,
                      hint: '代号',
                      maxLength: 16,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DoodleField(
                            controller: _recoverPassword,
                            hint: '密码',
                            obscure: true,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DoodleButton(
                          compact: true,
                          onPressed: _recovering ? null : _recover,
                          child: Text(_recovering ? '找回中…' : '找回'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ---------- 第三方登录 ----------
        DoodlePanel(
          tone: NoteTone.blue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SectionHead(title: '第三方登录', titleSize: 15),
              const SizedBox(height: 12),
              Text(
                '第三方快捷登录依赖浏览器回调，请在网页版完成；'
                '绑定后回到 App 用「邮箱 + 验证码」登录即可，绑定关系会自动同步。',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              DoodleButton(
                compact: true,
                icon: 'link',
                onPressed: () => openInAppWeb(
                  context,
                  url: '${XqfEnv.baseUrl}/account',
                  title: '网页版账号中心',
                ),
                child: const Text('前往网页版登录'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
