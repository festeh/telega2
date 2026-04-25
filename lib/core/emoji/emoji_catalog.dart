import 'package:telega2/core/emoji/emoji_catalog.g.dart';

export 'package:telega2/core/emoji/emoji_catalog.g.dart'
    show EmojiTile, kEmojiSheetCount, kEmojiTilePx, kEmojiSheetCols, kEmojiSheetRows;

class EmojiCatalog {
  EmojiCatalog._();

  static const int _maxSequenceCodeUnits = 32;

  static EmojiTile? find(String emoji) {
    return kEmojiCatalog[_canonicalize(emoji)];
  }

  /// Finds the longest emoji sequence in [text] starting at [start].
  /// Returns the end index (exclusive) on a hit, or null on no match.
  static int? longestMatchAt(String text, int start) {
    var bestEnd = -1;
    final maxLen = (text.length - start).clamp(0, _maxSequenceCodeUnits);
    for (var len = 1; len <= maxLen; len++) {
      final sub = text.substring(start, start + len);
      if (kEmojiCatalog.containsKey(_canonicalize(sub))) {
        bestEnd = start + len;
      }
    }
    return bestEnd > start ? bestEnd : null;
  }

  static String _canonicalize(String s) {
    if (!s.contains('\u{FE0F}')) return s;
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final unit = s.codeUnitAt(i);
      if (unit == 0xFE0F) continue;
      sb.writeCharCode(unit);
    }
    return sb.toString();
  }
}
