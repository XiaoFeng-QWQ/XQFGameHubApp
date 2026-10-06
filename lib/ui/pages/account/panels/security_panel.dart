import 'package:flutter/material.dart';

import '../../../../core/net/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../data/models/account.dart';
import '../../../../state/app_state.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/doodle_field.dart';
import '../../../widgets/fold_section.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/toast.dart';

/// 账号安全（对应 Web 端「账号安全」面板）。
///
/// `password_set=false`（OAuth / 邮箱注册的随机密码）时免旧密码，只展示「新密码」；
/// 修改成功后旧 token 失效，需用返回的新 token 覆盖本地会话。
class SecurityPanel extends StatefulWidget {
  const SecurityPanel({
    super.key,
    required this.overview,
    required this.onChanged,
    required this.onSignedOut,
  });

  final AccountOverview overview;
  final ValueChanged<AccountOverview> onChanged;
  final Future<void> Function() onSignedOut;

  @override
  State<SecurityPanel> createState() => _SecurityPanelState();
}

class _SecurityPanelState extends State<SecurityPanel> {
  final TextEditingController _oldPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final AppScope scope = AppScope.of(context);
    final bool needOld = widget.overview.passwordSet;
    final String newPassword = _newPassword.text;
    if (needOld && _oldPassword.text.isEmpty) {
      showTopToast(context, '请输入当前密码', isError: true);
      return;
    }
    if (newPassword.isEmpty) {
      showTopToast(context, '密码不能为空', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final String token = await scope.services.account.changePassword(
        newPassword: newPassword,
        oldPassword: needOld ? _oldPassword.text : null,
      );
      await scope.auth.replaceToken(token);
      _oldPassword.clear();
      _newPassword.clear();
      if (!mounted) return;
      showTopToast(context, '密码已更新');
      try {
        final AccountOverview data = await scope.services.account.overview();
        widget.onChanged(data);
      } on ApiException {
        // 忽略
      }
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final AppScope scope = AppScope.of(context);
    final bool ok = await showDoodleConfirm(
      context,
      title: '退出登录',
      message: '退出后需要重新用邮箱验证码登录，确定吗？',
      confirmText: '退出',
      danger: true,
    );
    if (!ok) return;
    await scope.auth.signOut();
    if (!mounted) return;
    showTopToast(context, '已退出登录');
    await widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool needOld = widget.overview.passwordSet;

    return DoodlePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHead(title: '账号安全', titleSize: 15),
          const SizedBox(height: 12),
          FoldSection(
            title: needOld ? '修改密码' : '设置密码',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (needOld) ...<Widget>[
                  DoodleField(
                    controller: _oldPassword,
                    hint: '当前密码',
                    obscure: true,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DoodleField(
                        controller: _newPassword,
                        hint: needOld ? '新密码' : '设置新密码',
                        obscure: true,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DoodleButton(
                      compact: true,
                      onPressed: _saving ? null : _savePassword,
                      child: Text(_saving ? '保存中…' : '保存'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '密码至少 8 位，需包含字母、数字、符号中的两类；不要用纯数字、'
                  '连续字符（123456 / abcdef / qwerty）或常见弱密码。'
                  '修改后其他设备上的登录状态会失效。',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.6,
                    color: p.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DashedDivider(color: p.borderLight),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: DoodleButton(
              compact: true,
              variant: DoodleButtonVariant.danger,
              icon: 'logout',
              onPressed: _logout,
              child: const Text('退出登录'),
            ),
          ),
        ],
      ),
    );
  }
}
