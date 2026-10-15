import 'dart:convert';

import 'package:crypto/crypto.dart' show sha1;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/credits.dart';
import 'package:verifin/app/credits_avatar.dart';

import 'support/test_harness.dart';

void main() {
  group('头像 SVG', () {
    test('同名同图，不同名不同图', () {
      expect(creditsAvatarSvg('wh3286'), creditsAvatarSvg('wh3286'));
      expect(creditsAvatarSvg('wh3286'), isNot(creditsAvatarSvg('爱发电用户_Jd7R')));
      // 名字大小写敏感：jdenticon 上游行为，两个不同的称呼不该撞成一张脸。
      expect(creditsAvatarSvg('wh3286'), isNot(creditsAvatarSvg('WH3286')));
    });

    test('是当前算法的快照：换算法必须在测试里显式确认', () {
      // 只锁一个指纹而不是整段 SVG：算法一变（上游升级、换库、参数调整），
      // 用户设备上的头像就会换脸，这种变化必须是有意为之。
      final fingerprint = sha1
          .convert(utf8.encode(creditsAvatarSvg('wh3286')))
          .toString();
      expect(fingerprint, '7cc287f0bbfb0c8511e0fae884fc80ffe7cd8533');
    });

    test('同时包含淡彩圆底与几何图形', () {
      final svg = creditsAvatarSvg('wh3286');
      expect(svg, startsWith('<svg '));
      expect(svg, contains('viewBox="0 0 200 200"'));
      // jdenticon 默认是透明底的三层图形，这里必须补上圆底（rect 带不透明 fill）。
      expect(
        svg,
        matches(RegExp(r'<rect width="200" height="200" fill="#[0-9a-f]{6}"')),
      );
      expect(svg, contains('opacity="1.00"'));
      expect(svg, contains('<path fill="#'));
    });
  });

  group('头像渲染', () {
    testWidgets('渲染成圆形切边的 SVG 图片且不报错', (tester) async {
      await tester.pumpWidget(
        zhMaterialApp(
          home: const Center(child: CreditsAvatar(seed: 'wh3286', size: 56)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('名单分组', () {
    test('当前名单只有一个默认组，且不产生组标题', () {
      final groups = creditsGroups();
      expect(groups.length, 1);
      expect(groups.single.title, isNull);
      expect(groups.single.members.length, creditsSupporters.length);
      expect(groups.single.members.map((member) => member.name), <String>[
        'wh3286',
        '爱发电用户_Jd7R',
      ]);
    });

    test('新分组按首次出现顺序追加，空分组不会出现', () {
      final groups = creditsGroups(
        supporters: const <CreditsSupporter>[
          CreditsSupporter('a'),
          CreditsSupporter('b', group: '特别鸣谢'),
          CreditsSupporter('c'),
          CreditsSupporter('d', group: '特别鸣谢'),
        ],
      );
      expect(groups.map((group) => group.title), <String?>[null, '特别鸣谢']);
      expect(groups.last.members.map((member) => member.name), <String>[
        'b',
        'd',
      ]);
    });

    test('空名单得到空列表', () {
      expect(creditsGroups(supporters: const <CreditsSupporter>[]), isEmpty);
    });

    test('头像种子默认取展示名，可用 seed 固定', () {
      const withSeed = CreditsSupporter('新名字', seed: 'wh3286');
      expect(withSeed.avatarSeed, 'wh3286');
      expect(const CreditsSupporter('wh3286').avatarSeed, 'wh3286');
    });
  });
}
