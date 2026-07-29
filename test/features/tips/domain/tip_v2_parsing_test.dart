import 'package:flutter_test/flutter_test.dart';
import 'package:howtocook/features/tips/domain/entities/tip.dart';

void main() {
  group('V2 tutorial parsing', () {
    test('accepts upstream repository source objects', () {
      final tip = Tip.fromJson({
        'schemaVersion': 2,
        'id': 'tips_advanced_120ea12c',
        'title': '辅料技巧',
        'category': 'advanced',
        'categoryName': '进阶知识',
        'content': '先放姜、后放葱和蒜。',
        'sections': [
          {'title': '放盐时机', 'content': '汤料理最后再放盐。'},
        ],
        'source': {
          'repository': 'https://github.com/Gaq152/HowToCook',
          'commit': 'c05758fa',
          'path': 'tips/advanced/辅料技巧.md',
        },
        'hash': 'tip-hash',
      });

      expect(tip.title, '辅料技巧');
      expect(tip.content, isNotEmpty);
      expect(tip.sections.single.title, '放盐时机');
      expect(tip.source, TipSource.bundled);
      expect(tip.toJson()['source'], 'bundled');
    });

    test('keeps local tutorial source enum strings', () {
      final tip = Tip.fromJson({
        'id': 'local-tip',
        'title': '我的技巧',
        'category': 'general',
        'categoryName': '基础知识',
        'content': '本地内容',
        'hash': 'local-hash',
        'source': 'userCreated',
      });

      expect(tip.source, TipSource.userCreated);
    });
  });
}
