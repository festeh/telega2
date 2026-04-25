import 'package:telega2/core/emoji/emoji_catalog.dart';

/// Walks [text] greedily picking the longest catalog-known emoji sequence at
/// each position. ZWJ families and skin-toned variants resolve to a single
/// segment. Anything not in the catalog stays as plain text.
List<EmojiSegment> splitTextWithEmojis(String text) {
  final segments = <EmojiSegment>[];
  var textStart = 0;
  var i = 0;
  while (i < text.length) {
    final end = EmojiCatalog.longestMatchAt(text, i);
    if (end == null) {
      i++;
      continue;
    }
    if (i > textStart) {
      segments.add(EmojiSegment(text: text.substring(textStart, i), isEmoji: false));
    }
    segments.add(EmojiSegment(text: text.substring(i, end), isEmoji: true));
    i = end;
    textStart = end;
  }
  if (textStart < text.length) {
    segments.add(EmojiSegment(text: text.substring(textStart), isEmoji: false));
  }
  return segments;
}

bool containsEmoji(String text) {
  var i = 0;
  while (i < text.length) {
    final end = EmojiCatalog.longestMatchAt(text, i);
    if (end != null) return true;
    i++;
  }
  return false;
}

int countEmojis(String text) {
  var count = 0;
  var i = 0;
  while (i < text.length) {
    final end = EmojiCatalog.longestMatchAt(text, i);
    if (end != null) {
      count++;
      i = end;
    } else {
      i++;
    }
  }
  return count;
}

bool isOnlyEmojis(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  var i = 0;
  while (i < trimmed.length) {
    final end = EmojiCatalog.longestMatchAt(trimmed, i);
    if (end == null) return false;
    i = end;
    while (i < trimmed.length && _isWhitespace(trimmed.codeUnitAt(i))) {
      i++;
    }
  }
  return true;
}

int getOnlyEmojiCount(String text) {
  if (!isOnlyEmojis(text)) return 0;
  return countEmojis(text);
}

List<String> findEmojis(String text) {
  final results = <String>[];
  var i = 0;
  while (i < text.length) {
    final end = EmojiCatalog.longestMatchAt(text, i);
    if (end != null) {
      results.add(text.substring(i, end));
      i = end;
    } else {
      i++;
    }
  }
  return results;
}

class EmojiSegment {
  final String text;
  final bool isEmoji;

  const EmojiSegment({required this.text, required this.isEmoji});

  @override
  String toString() => 'EmojiSegment(text: $text, isEmoji: $isEmoji)';
}

bool _isWhitespace(int codeUnit) {
  return codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0D ||
      codeUnit == 0xA0;
}
