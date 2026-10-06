import 'package:flutter/material.dart';

import '../../core/env.dart';
import '../../core/theme/palette.dart';
import '../widgets/app_header.dart';
import '../widgets/app_icon.dart';
import '../widgets/doodle.dart';
import '../widgets/paper.dart';
import '../widgets/sponsor.dart';
import 'web_page.dart';

/// 关于页。
///
/// 原先挂在首页 / 账号页底部的「网页式页脚」（ICP 备案、协议入口、赞助）
/// 全部收进这里，主滚动流里不再出现备案号这类网页元素。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);

    return Scaffold(
      backgroundColor: p.paperBg,
      body: DotGridBackground(
        child: Column(
          children: <Widget>[
            AppHeader(
              title: '关于 ${XqfEnv.appName}',
              leading: HeaderIconButton(
                icon: 'arrow-left',
                tooltip: '返回',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const _BrandCard(),
                        const SizedBox(height: 22),
                        const _LinkPanel(title: '服务与协议'),
                        const SizedBox(height: 22),
                        const _TechPanel(),
                        const SizedBox(height: 22),
                        const _FilingPanel(),
                        const SizedBox(height: 26),
                        Center(
                          child: Text(
                            '© ${DateTime.now().year} ${XqfEnv.appName} · 保留所有权利',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: p.textSubtle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return DoodlePanel(
      tone: NoteTone.yellow,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 6),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: p.surfaceWhite,
              border: Border.all(color: p.inkBlack, width: 2),
              borderRadius: XqfRadii.hand,
              boxShadow: XqfShadows.stat(p),
            ),
            child: Center(
              child: AppIcon('grid', size: 38, color: p.inkBlue),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            XqfEnv.appName,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: p.inkBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            XqfEnv.appNameCn,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              letterSpacing: 3,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          DoodleTag(label: 'v${XqfEnv.version}', solid: true),
          const SizedBox(height: 14),
          Text(
            '屏幕那边，不止一场对局。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.7,
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkPanel extends StatelessWidget {
  const _LinkPanel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DoodlePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHead(title: title, titleSize: 15),
          const SizedBox(height: 6),
          _AboutRow(
            icon: 'shield',
            label: '用户协议',
            hint: '注册与使用的约定',
            onTap: () => openInAppWeb(context, url: XqfEnv.agreementUrl, title: '用户协议'),
          ),
          _AboutRow(
            icon: 'lock',
            label: '隐私政策',
            hint: '我们如何收集与保护信息',
            onTap: () => openInAppWeb(context, url: XqfEnv.privacyUrl, title: '隐私政策'),
          ),
          _AboutRow(
            icon: 'server',
            label: '服务器状态',
            hint: '实时可用性监控',
            onTap: () => openInAppWeb(context, url: XqfEnv.statusUrl, title: '服务器状态'),
          ),
          _AboutRow(
            icon: 'heart',
            label: '赞助支持',
            hint: '请作者喝杯咖啡',
            // 这里本来就是弹窗，不该跳外链
            onTap: () => showSponsorDialog(context),
          ),
        ],
      ),
    );
  }
}

class _TechPanel extends StatelessWidget {
  const _TechPanel();

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return DoodlePanel(
      tone: NoteTone.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHead(title: '客户端信息', titleSize: 15),
          const SizedBox(height: 10),
          _KeyValue(label: '客户端版本', value: 'v${XqfEnv.version}'),
          _KeyValue(label: '构建方式', value: 'Flutter · Android'),
          _KeyValue(label: '接口地址', value: XqfEnv.baseUrl),
          const SizedBox(height: 8),
          Text(
            '界面风格与网页版共用同一套设计变量：2px 手绘描边、不规则圆角、'
            '错位实心阴影、便签底色与点阵纸背景。',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.7,
              color: p.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilingPanel extends StatelessWidget {
  const _FilingPanel();

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return DoodlePanel(
      tone: NoteTone.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHead(title: '备案信息', titleSize: 15),
          const SizedBox(height: 6),
          _AboutRow(
            icon: 'info',
            label: '萌ICP备20269944号',
            onTap: () => openInAppWeb(
              context,
              url: 'https://icp.gov.moe/?keyword=20269944',
              title: '萌ICP备20269944号',
            ),
          ),
          _AboutRow(
            icon: 'info',
            label: '假ICP备1202612号',
            hint: '非官方备案，仅供娱乐',
            onTap: () => openInAppWeb(
              context,
              url: 'https://fakeicp.top/query.html?number=1202612',
              title: '假ICP备1202612号',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '本站为个人兴趣项目，与任何商业实体无关。',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.7,
              color: p.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    this.hint,
    required this.onTap,
  });

  final String icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: <Widget>[
            AppIcon(icon, size: 16, color: p.inkBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: p.inkBlack,
                    ),
                  ),
                  if (hint != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: p.textSubtle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppIcon('chevron-right', size: 15, color: p.textAa),
          ],
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 80,
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
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: p.inkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
