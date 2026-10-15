import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/credits.dart';
import 'package:verifin/app/credits_avatar.dart';

/// WCAG 相对亮度。
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// 两色对比度（1–21）。用 pow 逐通道换算，见 WCAG 2.1 相对亮度定义。
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('头像哈希', () {
    test('同名同值，且随机名不碰撞', () {
      expect(creditsAvatarHash('wh3286'), creditsAvatarHash('wh3286'));
      expect(
        creditsAvatarHash('wh3286'),
        isNot(creditsAvatarHash('爱发电用户_Jd7R')),
      );
    });

    test('是写死的快照：算法一旦变化必须显式改动这里', () {
      // 头像必须「写死一次、永远一样」：升级 Flutter / 换 SDK 都不能让已经出现在
      // 用户设备上的头像换脸，所以哈希结果按快照固定下来（不用 String.hashCode）。
      // '' 必须等于 FNV-1a 的偏移基数，可用来一眼看出算法有没有被换掉。
      expect(creditsAvatarHash(''), 2166136261);
      expect(creditsAvatarHash('wh3286'), 1352441597);
      expect(creditsAvatarHash('爱发电用户_Jd7R'), 1159742380);
    });
  });

  group('头像点阵', () {
    test('左右对称且至少有一个方块', () {
      for (final seed in <String>['wh3286', '爱发电用户_Jd7R', '', '  ', 'a']) {
        final pattern = creditsAvatarPattern(seed);
        expect(pattern.length, creditsAvatarGridSize);
        var filled = 0;
        for (var row = 0; row < creditsAvatarGridSize; row++) {
          for (var col = 0; col < creditsAvatarGridSize; col++) {
            expect(
              pattern[row][col],
              pattern[row][creditsAvatarGridSize - 1 - col],
              reason: '$seed 的第 $row 行不左右对称',
            );
            if (pattern[row][col]) {
              filled++;
            }
          }
        }
        expect(filled, greaterThan(0), reason: '$seed 生成了空点阵');
        expect(filled, lessThan(creditsAvatarGridSize * creditsAvatarGridSize));
      }
    });

    test('同一种子每次生成同一张图', () {
      expect(creditsAvatarPattern('wh3286'), creditsAvatarPattern('wh3286'));
    });
  });

  group('身份色板', () {
    test('每个底色与图案色的对比度都不低于 4.5:1', () {
      for (final style in creditsAvatarStyles) {
        expect(
          _contrast(style.background, style.mark),
          greaterThanOrEqualTo(4.5),
          reason: '${style.background} 与 ${style.mark} 对比度不足',
        );
      }
    });

    test('取色是纯函数：同名同色', () {
      expect(
        creditsAvatarStyleFor('wh3286').background,
        creditsAvatarStyleFor('wh3286').background,
      );
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
