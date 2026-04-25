import 'package:flutter_test/flutter_test.dart';
import 'package:telega2/core/emoji/emoji_catalog.dart';

void main() {
  group('EmojiCatalog.find', () {
    test('grinning face is at sprite 0, row 0, col 0', () {
      final tile = EmojiCatalog.find('😀');
      expect(tile, isNotNull);
      expect(tile!.sprite, 0);
      expect(tile.row, 0);
      expect(tile.col, 0);
    });

    test('thumbs up resolves', () {
      expect(EmojiCatalog.find('👍'), isNotNull);
    });

    test('thumbs up with skin tone resolves to a different tile', () {
      final base = EmojiCatalog.find('👍');
      final toned = EmojiCatalog.find('👍🏽');
      expect(base, isNotNull);
      expect(toned, isNotNull);
      expect(
        base!.sprite != toned!.sprite ||
            base.row != toned.row ||
            base.col != toned.col,
        isTrue,
      );
    });

    test('FE0F variant selector is stripped — both forms resolve to same tile',
        () {
      final bare = EmojiCatalog.find('☺');
      final withFe0f = EmojiCatalog.find('☺\u{FE0F}');
      expect(bare, isNotNull);
      expect(withFe0f, isNotNull);
      expect(bare!.sprite, withFe0f!.sprite);
      expect(bare.row, withFe0f.row);
      expect(bare.col, withFe0f.col);
      expect(bare.postfixed, isTrue);
    });

    test('heart-on-fire ZWJ resolves both with and without FE0F',
        () {
      // TDLib reaction payloads sometimes ship this without the FE0F that
      // tdesktop's emoji.txt declares — this test pins the regression where
      // the catalog used to key entries with FE0F intact, missing the bare form.
      final bare = EmojiCatalog.find('\u{2764}\u{200D}\u{1F525}');
      final withFe0f = EmojiCatalog.find('\u{2764}\u{FE0F}\u{200D}\u{1F525}');
      expect(bare, isNotNull);
      expect(withFe0f, isNotNull);
      expect(bare!.sprite, withFe0f!.sprite);
      expect(bare.row, withFe0f.row);
      expect(bare.col, withFe0f.col);
    });

    test('ZWJ family sequence resolves as one tile', () {
      expect(EmojiCatalog.find('👨\u{200D}👩\u{200D}👧\u{200D}👦'), isNotNull);
    });

    test('regional flag pair (Andorra) resolves', () {
      expect(EmojiCatalog.find('🇦🇩'), isNotNull);
    });

    test('non-emoji string returns null', () {
      expect(EmojiCatalog.find('hello'), isNull);
      expect(EmojiCatalog.find('A'), isNull);
    });
  });

  group('EmojiCatalog.longestMatchAt', () {
    test('matches a single emoji at the start', () {
      const text = '👍 ok';
      final end = EmojiCatalog.longestMatchAt(text, 0);
      expect(end, 2); // 👍 is one surrogate pair = 2 code units
    });

    test('matches the long ZWJ family rather than just the first head', () {
      const text = '👨\u{200D}👩\u{200D}👧\u{200D}👦 family';
      final end = EmojiCatalog.longestMatchAt(text, 0);
      expect(end, 11); // 4 surrogate pairs (8) + 3 ZWJ (3) = 11
    });

    test('returns null at non-emoji position', () {
      const text = 'hello 👍';
      expect(EmojiCatalog.longestMatchAt(text, 0), isNull);
      expect(EmojiCatalog.longestMatchAt(text, 6), isNotNull);
    });

    test('matches skin-toned emoji greedily over its base', () {
      const text = '👍🏿';
      final end = EmojiCatalog.longestMatchAt(text, 0);
      expect(end, 4); // 👍 (2) + skin tone (2) = 4 code units
    });
  });
}
