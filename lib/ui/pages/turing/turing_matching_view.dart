import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../../data/turing/turing_client.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fold_section.dart';

/// 匹配中：等待服务端下发 `matched`。
///
/// 对应 Web 端 `#matching-page` 的 `.matching-card`。
class TuringMatchingView extends StatelessWidget {
  const TuringMatchingView({super.key, required this.client});

  final TuringClient client;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: DoodlePanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '正在为你寻找对手…',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: p.inkBlack,
                  ),
                ),
                const SizedBox(height: 18),
                const DotBounce(),
                const SizedBox(height: 16),
                Text(
                  client.connected ? '稍等一下，马上就好' : '正在连接服务器…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: p.textSubtle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '对手可能是真人，也可能是 AI —— 这正是要猜的',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.6,
                    color: p.textAa,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
