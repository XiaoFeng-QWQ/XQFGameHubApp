import 'package:flutter/material.dart';

import '../../../../core/env.dart';
import '../../../../core/net/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/xqf_time.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/oauth.dart';
import '../../../../state/app_state.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/fold_section.dart';
import '../../../widgets/toast.dart';
import '../../web_page.dart';

/// 第三方绑定（对应 Web 端「第三方绑定」面板）。
///
/// 解绑与「同步头像」都是普通鉴权接口，App 内可直接完成；
/// 新增绑定依赖浏览器 OAuth 回调，引导到网页版。
class BindingsPanel extends StatefulWidget {
  const BindingsPanel({super.key, required this.overview, required this.onChanged});

  final AccountOverview overview;
  final ValueChanged<AccountOverview> onChanged;

  @override
  State<BindingsPanel> createState() => _BindingsPanelState();
}

class _BindingsPanelState extends State<BindingsPanel> {
  List<OAuthBinding>? _bindings;
  List<OAuthProvider> _providers = const <OAuthProvider>[];
  bool _loading = true;
  String? _error;
  String _busyProvider = '';

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
      final List<OAuthBinding> bindings = await scope.services.account.oauthBindings();
      List<OAuthProvider> providers = const <OAuthProvider>[];
      try {
        providers = await scope.services.account.oauthProviders();
      } on ApiException {
        // 提供商列表拿不到不影响已绑定列表
      }
      if (!mounted) return;
      setState(() {
        _bindings = bindings;
        _providers = providers;
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

  String _providerName(String key) {
    for (final OAuthProvider p in _providers) {
      if (p.key == key) return p.name;
    }
    return key;
  }

  Future<void> _unbind(OAuthBinding b) async {
    final AppScope scope = AppScope.of(context);
    final bool ok = await showDoodleConfirm(
      context,
      title: '解绑 ${_providerName(b.provider)}',
      message: '解绑后将无法使用该平台一键登录，确定继续吗？',
      confirmText: '解绑',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busyProvider = b.provider);
    try {
      await scope.services.account.unbindOAuth(b.provider);
      if (mounted) showTopToast(context, '已解绑 ${_providerName(b.provider)}');
      await _load();
      await _refreshOverview();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busyProvider = '');
    }
  }

  Future<void> _syncAvatar(OAuthBinding b) async {
    final AppScope scope = AppScope.of(context);
    setState(() => _busyProvider = b.provider);
    try {
      await scope.services.account.syncOAuthAvatar(b.provider);
      if (mounted) showTopToast(context, '头像已同步');
      await _refreshOverview();
    } on ApiException catch (e) {
      if (mounted) showTopToast(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busyProvider = '');
    }
  }

  Future<void> _refreshOverview() async {
    final AppScope scope = AppScope.of(context);
    try {
      final AccountOverview data = await scope.services.account.overview();
      widget.onChanged(data);
    } on ApiException {
      // 忽略
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final List<OAuthBinding> bindings = _bindings ?? const <OAuthBinding>[];

    return DoodlePanel(
      tone: NoteTone.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHead(title: '第三方绑定', titleSize: 15),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: DotBounce()),
            )
          else if (_error != null)
            EmptyTip(text: _error!, isError: true)
          else if (bindings.isEmpty)
            const EmptyTip(text: '还没有绑定任何第三方账号')
          else
            for (final OAuthBinding b in bindings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.surfaceWhite,
                    border: Border.all(color: p.inkBlack, width: 2),
                    borderRadius: XqfRadii.input,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _providerName(b.provider),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: p.inkBlack,
                              ),
                            ),
                          ),
                          if (b.createdAt != null)
                            Text(
                              '绑定于 ${XqfTime.formatDate(b.createdAt)}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: p.textSubtle,
                              ),
                            ),
                        ],
                      ),
                      if (b.email != null && b.email!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          b.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: p.textSubtle,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: <Widget>[
                          DoodleButton(
                            compact: true,
                            onPressed: _busyProvider == b.provider
                                ? null
                                : () => _syncAvatar(b),
                            child: const Text('同步头像'),
                          ),
                          DoodleButton(
                            compact: true,
                            variant: DoodleButtonVariant.danger,
                            onPressed: _busyProvider == b.provider
                                ? null
                                : () => _unbind(b),
                            child: const Text('解绑'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 10),
          Text(
            '新增绑定需要在浏览器里完成第三方授权回调，请前往网页版账号中心操作；'
            '绑定后回到 App 用「邮箱 + 验证码」登录即可。',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.6,
              color: p.textSubtle,
            ),
          ),
          const SizedBox(height: 10),
          DoodleButton(
            compact: true,
            icon: 'link',
            onPressed: () => openInAppWeb(
              context,
              url: '${XqfEnv.baseUrl}/account',
              title: '网页版账号中心',
            ),
            child: const Text('前往网页版绑定'),
          ),
        ],
      ),
    );
  }
}
