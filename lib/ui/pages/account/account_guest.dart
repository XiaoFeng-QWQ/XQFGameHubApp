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
import '../../widgets/toast.dart';
import '../web_page.dart';

/// 登录方式。两种方式共用一张卡，用胶囊 tab 切换。
enum _LoginMode { email, password }

/// 未登录视图（对应 Web 端 `#account-guest`）。
///
/// 与 Web 端的差异：Web 端把「邮箱登录 / 注册」和「找回账号」摆成上下两张卡片，
/// 这里合并成一张卡 + 两个 tab —— 手机屏窄，两张卡意味着要滚动才能看全，
/// 而它们本来就是「同一件事的两种做法」。合并后省掉一张卡的高度，
/// 也去掉了原来那个「已有旧账号？」的折叠区（多一次点击才展开）。
///
/// 第三方 OAuth 登录需要浏览器回调，App 内无法完成，仍引导去网页版。
class AccountGuestView extends StatefulWidget {
  const AccountGuestView({super.key, required this.onSignedIn});

  final Future<void> Function() onSignedIn;

  @override
  State<AccountGuestView> createState() => _AccountGuestViewState();
}

class _AccountGuestViewState extends State<AccountGuestView> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _nickname = TextEditingController();
  final TextEditingController _password = TextEditingController();

  _LoginMode _mode = _LoginMode.email;

  bool _sending = false;
  bool _submitting = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  bool get _isEmailMode => _mode == _LoginMode.email;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _email.dispose();
    _code.dispose();
    _nickname.dispose();
    _password.dispose();
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

  /// 邮箱验证码登录 / 注册（新邮箱自动建号）。
  Future<void> _submitEmail() async {
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

  /// 账号密码登录。
  ///
  /// 后端 `GET /api/generate-player-id?action=recover` 就是「代号 + 密码换 token」，
  /// 即密码登录本身。**注意它只对已设置密码的账号有效**：邮箱注册的账号
  /// `password_hash` 默认为空串，`password_verify` 必然失败，所以文案里要讲清楚。
  Future<void> _submitPassword() async {
    final AppScope scope = AppScope.of(context);
    final String nickname = _nickname.text.trim();
    final String password = _password.text;
    if (nickname.isEmpty) {
      showTopToast(context, '请输入代号', isError: true);
      return;
    }
    if (password.isEmpty) {
      showTopToast(context, '请输入密码', isError: true);
      return;
    }
    setState(() => _submitting = true);
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
      showTopToast(context, '登录成功：${result.nickname}');
      await widget.onSignedIn();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ---------- 登录 / 注册（两个 tab 共用一张卡） ----------
        DoodlePanel(
          tone: NoteTone.yellow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionHead(
                title: '登录账号',
                note: _isEmailMode ? '新邮箱自动创建账号' : '仅限已设置密码的账号',
                titleSize: 15,
              ),
              const SizedBox(height: 14),

              // tab 切换（与 Web 端 `.acc-sticker-tab` 同一形态）
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  DoodleChoiceChip(
                    label: '邮箱验证码',
                    active: _isEmailMode,
                    onTap: () => setState(() => _mode = _LoginMode.email),
                  ),
                  DoodleChoiceChip(
                    label: '账号密码',
                    active: !_isEmailMode,
                    onTap: () => setState(() => _mode = _LoginMode.password),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // tab 内容：两个表单高度不同，用 AnimatedSize 平滑过渡，
              // 避免切换时整张卡「跳」一下（时长对齐 DESIGN.md 的折叠展开 200ms）
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isEmailMode ? _buildEmailForm(p) : _buildPasswordForm(p),
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

  Widget _buildEmailForm(XqfPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
          onPressed: _submitting ? null : _submitEmail,
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
    );
  }

  Widget _buildPasswordForm(XqfPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DoodleField(
          controller: _nickname,
          hint: '代号',
          maxLength: 16,
          fontSize: 14,
          autofillHints: const <String>[AutofillHints.username],
        ),
        const SizedBox(height: 10),
        DoodleField(
          controller: _password,
          hint: '密码',
          obscure: true,
          fontSize: 14,
          autofillHints: const <String>[AutofillHints.password],
        ),
        const SizedBox(height: 14),
        DoodleButton(
          expand: true,
          icon: 'key',
          fontSize: 15,
          padding: const EdgeInsets.symmetric(vertical: 12),
          onPressed: _submitting ? null : _submitPassword,
          child: Text(_submitting ? '登录中…' : '登录'),
        ),
        const SizedBox(height: 12),
        Text(
          '仅适用于已设置密码的账号：旧版「代号 + 密码」账号，'
          '或在「账号安全」里设过密码的邮箱账号。'
          '邮箱注册后从未设置密码的，请改用「邮箱验证码」登录。',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.6,
            color: p.textSubtle,
          ),
        ),
      ],
    );
  }
}
