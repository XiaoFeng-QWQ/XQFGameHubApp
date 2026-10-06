// XQFGameHub —— 基础单元测试。
//
// 只覆盖与网络无关的纯逻辑（时间格式化、设计变量、手绘圆角、模型映射），
// 页面级测试需要真实后端，放在集成测试里做。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xqf_game_hub/core/net/api_client.dart';
import 'package:xqf_game_hub/core/theme/palette.dart';
import 'package:xqf_game_hub/core/utils/xqf_time.dart';
import 'package:xqf_game_hub/data/models/chat_history.dart';
import 'package:xqf_game_hub/data/models/tags.dart';

void main() {
  group('XqfTime', () {
    test('秒级时间戳解析', () {
      expect(XqfTime.toEpoch(1751000000), 1751000000);
      expect(XqfTime.formatDate(1751000000), isNot('—'));
    });

    test('毫秒级时间戳自动识别', () {
      expect(XqfTime.toEpoch(1751000000000), 1751000000);
    });

    test('非法值返回占位符', () {
      expect(XqfTime.formatDate(null), '—');
      expect(XqfTime.formatDate(''), '—');
      expect(XqfTime.timeAgo(0), '—');
    });

    test('时长格式化', () {
      expect(XqfTime.duration(45), '45 秒');
      expect(XqfTime.duration(600), '10 分钟');
      expect(XqfTime.duration(0), '—');
    });
  });

  group('XqfPalette', () {
    test('亮色 / 暗色变量与 style.css 对齐', () {
      expect(XqfPalette.light.paperBg, const Color(0xFFF8F9FA));
      expect(XqfPalette.dark.paperBg, const Color(0xFF121220));
      expect(XqfPalette.light.inkBlack, const Color(0xFF2B2B2B));
      expect(XqfPalette.dark.inkBlue, const Color(0xFF7AA2F7));
    });
  });

  group('XqfRadii', () {
    test('手绘圆角对应 border-radius: 255px 15px 225px 15px / 15px 225px 15px 255px', () {
      expect(XqfRadii.hand.topLeft, const Radius.elliptical(255, 15));
      expect(XqfRadii.hand.topRight, const Radius.elliptical(15, 225));
      expect(XqfRadii.hand.bottomRight, const Radius.elliptical(225, 15));
      expect(XqfRadii.hand.bottomLeft, const Radius.elliptical(15, 255));
    });
  });

  group('parseApiError 结果约定', () {
    test('约定 A：error 字段', () {
      expect(parseApiError(<String, dynamic>{'error': '昵称不能为空'}), '昵称不能为空');
      expect(parseApiError(<String, dynamic>{'ok': false, 'error': '缺少 token'}), '缺少 token');
    });

    test('约定 B：success=false + message（没有 error 字段）', () {
      // 这正是 POST /api/player/worn-tags 的失败形态，只看 error 会漏判
      expect(
        parseApiError(<String, dynamic>{'success': false, 'message': '玩家不存在'}),
        '玩家不存在',
      );
      expect(parseApiError(<String, dynamic>{'success': false}), '操作失败');
    });

    test('成功响应不应被判为错误', () {
      expect(parseApiError(<String, dynamic>{'success': true, 'message': '标签佩戴已更新'}), isNull);
      expect(parseApiError(<String, dynamic>{'ok': true, 'token': 'x'}), isNull);
      expect(parseApiError(<String, dynamic>{'nickname': '小明'}), isNull);
      expect(parseApiError(null), isNull);
    });

    test('ok=false 无 message 时给出兜底文案', () {
      expect(parseApiError(<String, dynamic>{'ok': false}), '操作失败');
    });
  });

  group('MyTags 解析', () {
    // 回归用例：线上 /api/player/tags 的真实返回（与文档不一致）。
    // tags 是对象数组 [{tag, count, is_special}]，special 是字符串数组。
    final Map<String, dynamic> payload = <String, dynamic>{
      'tags': <dynamic>[
        <String, dynamic>{'tag': '刘小枫', 'count': 0, 'is_special': 1},
        <String, dynamic>{'tag': '哈基枫😋', 'count': 0, 'is_special': 1},
        <String, dynamic>{'tag': '国庆限定', 'count': 0, 'is_special': 1},
        <String, dynamic>{'tag': '开国大典', 'count': 0, 'is_special': 1},
        <String, dynamic>{'tag': '枫枫枫', 'count': 0, 'is_special': 1},
      ],
      'worn': <dynamic>[],
      'special': <dynamic>['刘小枫', '哈基枫😋', '国庆限定', '开国大典', '枫枫枫'],
      'worn_special': <dynamic>['哈基枫😋', '刘小枫', '枫枫枫'],
      'max': 3,
    };

    test('对象数组不再被字符串化成原始 JSON', () {
      final MyTags tags = MyTags.fromJson(payload);
      expect(tags.tags.length, 5);
      expect(tags.tags.first.name, '刘小枫');
      expect(tags.tags.first.isSpecial, isTrue);
      for (final PlayerTag t in tags.tags) {
        expect(t.name.contains('{'), isFalse, reason: '不应出现 Map 的 toString');
      }
    });

    test('全部为特殊称号时普通标签为空', () {
      final MyTags tags = MyTags.fromJson(payload);
      expect(tags.normalTags, isEmpty);
      expect(tags.specialTags.length, 5);
      expect(tags.specialTags.map((SpecialTag t) => t.name), contains('国庆限定'));
      expect(tags.isEmpty, isFalse);
    });

    test('佩戴状态与上限', () {
      final MyTags tags = MyTags.fromJson(payload);
      expect(tags.worn, isEmpty);
      expect(tags.wornSpecial.length, 3);
      expect(tags.max, 3);
    });

    test('文档写法的字符串数组同样兼容', () {
      final MyTags tags = MyTags.fromJson(<String, dynamic>{
        'tags': <dynamic>['理性', '幽默'],
        'worn': <dynamic>['理性'],
        'special': <dynamic>[
          <String, dynamic>{'name': '新年快乐', 'icon': '🎉'},
        ],
        'worn_special': <dynamic>[],
        'max': 3,
      });
      expect(tags.normalTags.length, 2);
      expect(tags.normalTags.first.count, 0);
      expect(tags.specialTags.single.name, '新年快乐');
      expect(tags.specialTags.single.icon, '🎉');
    });
  });

  group('WornTagsResult', () {
    test('线上用 success 而非 ok', () {
      final WornTagsResult r = WornTagsResult.fromJson(<String, dynamic>{
        'success': true,
        'worn': <dynamic>['理性'],
        'worn_special': <dynamic>['国庆限定'],
        'message': '已保存',
      });
      expect(r.success, isTrue);
      expect(r.worn, <String>['理性']);
      expect(r.wornSpecial, <String>['国庆限定']);
      expect(r.message, '已保存');
    });

    test('success=false 时视为失败', () {
      final WornTagsResult r = WornTagsResult.fromJson(<String, dynamic>{
        'success': false,
        'message': '最多佩戴 3 个标签',
      });
      expect(r.success, isFalse);
      expect(r.message, '最多佩戴 3 个标签');
    });
  });

  group('ChatHistoryItem', () {
    test('标签映射', () {
      const ChatHistoryItem win = ChatHistoryItem(
        id: 1,
        playerGuess: 'ai',
        opponentTruth: 'human',
        result: 'win',
      );
      expect(win.resultLabel, '胜');
      expect(win.guessLabel, '猜AI');
      expect(win.truthLabel, '对方是人类');
    });

    test('无标题时用双方昵称拼接', () {
      const ChatHistoryItem item =
          ChatHistoryItem(id: 2, playerName: '小明', opponentName: '小红');
      expect(item.displayTitle, '小明 vs 小红');
    });
  });
}
