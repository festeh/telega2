import 'package:flutter_test/flutter_test.dart';
import 'package:telega2/core/emoji/emoji_utils.dart';

void main() {
  group('splitTextWithEmojis', () {
    test('plain text is one segment', () {
      final segs = splitTextWithEmojis('hello world');
      expect(segs.length, 1);
      expect(segs[0].isEmoji, isFalse);
      expect(segs[0].text, 'hello world');
    });

    test('text + emoji + text → three segments', () {
      final segs = splitTextWithEmojis('hi 👍 ok');
      expect(segs.length, 3);
      expect(segs[0].text, 'hi ');
      expect(segs[0].isEmoji, isFalse);
      expect(segs[1].text, '👍');
      expect(segs[1].isEmoji, isTrue);
      expect(segs[2].text, ' ok');
      expect(segs[2].isEmoji, isFalse);
    });

    test('ZWJ family stays as a single emoji segment', () {
      const family = '👨\u{200D}👩\u{200D}👧\u{200D}👦';
      final segs = splitTextWithEmojis('our $family is here');
      final emojiSegs = segs.where((s) => s.isEmoji).toList();
      expect(emojiSegs.length, 1);
      expect(emojiSegs.single.text, family);
    });

    test('skin-toned emoji is a single segment', () {
      final segs = splitTextWithEmojis('go 👍🏿!');
      final emojiSegs = segs.where((s) => s.isEmoji).toList();
      expect(emojiSegs.length, 1);
      expect(emojiSegs.single.text, '👍🏿');
    });

    test('two adjacent emojis become two segments', () {
      final segs = splitTextWithEmojis('👍👎');
      final emojiSegs = segs.where((s) => s.isEmoji).toList();
      expect(emojiSegs.length, 2);
      expect(emojiSegs[0].text, '👍');
      expect(emojiSegs[1].text, '👎');
    });
  });

  group('containsEmoji + countEmojis + isOnlyEmojis', () {
    test('plain text has no emoji', () {
      expect(containsEmoji('hello'), isFalse);
      expect(countEmojis('hello'), 0);
      expect(isOnlyEmojis('hello'), isFalse);
    });

    test('one emoji', () {
      expect(containsEmoji('hi 👍'), isTrue);
      expect(countEmojis('hi 👍 there 👎'), 2);
      expect(isOnlyEmojis('hi 👍'), isFalse);
    });

    test('only emojis', () {
      expect(isOnlyEmojis('👍 👎 🔥'), isTrue);
      expect(getOnlyEmojiCount('👍 👎 🔥'), 3);
      expect(getOnlyEmojiCount('👍 hi 👎'), 0);
    });
  });
}
