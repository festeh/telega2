/// Utilities for emoji detection and manipulation

/// Regex pattern to match emoji characters including:
/// - Basic emoji (Emoji_Presentation)
/// - Extended pictographics
/// - ZWJ sequences (e.g., family emojis 👨‍👩‍👧)
/// - Skin tone modifiers
/// - Flag sequences
final RegExp emojiRegex = RegExp(
  r'(?:'
  // Regional indicator pairs (flags)
  r'[\u{1F1E6}-\u{1F1FF}]{2}'
  r'|'
  // Tag sequences (e.g., flag subdivisions)
  r'\u{1F3F4}[\u{E0060}-\u{E007F}]+\u{E007F}'
  r'|'
  // ZWJ sequences and complex emoji
  r'(?:'
  r'[\u{1F468}\u{1F469}]'
  r'(?:\u{1F3FB}|\u{1F3FC}|\u{1F3FD}|\u{1F3FE}|\u{1F3FF})?'
  r'(?:\u200D[\u{1F468}\u{1F469}\u{1F467}\u{1F466}](?:\u{1F3FB}|\u{1F3FC}|\u{1F3FD}|\u{1F3FE}|\u{1F3FF})?)*'
  r')'
  r'|'
  // Keycap sequences
  r'[0-9#*]\uFE0F?\u20E3'
  r'|'
  // Emoji with skin tone modifiers
  r'[\u{1F3C2}-\u{1F3CC}\u{1F3F3}-\u{1F3F4}\u{1F441}\u{1F466}-\u{1F478}\u{1F47C}\u{1F481}-\u{1F483}\u{1F485}-\u{1F487}\u{1F4AA}\u{1F574}-\u{1F575}\u{1F57A}\u{1F590}\u{1F595}-\u{1F596}\u{1F645}-\u{1F647}\u{1F64B}-\u{1F64F}\u{1F6A3}\u{1F6B4}-\u{1F6B6}\u{1F6C0}\u{1F6CC}\u{1F90C}-\u{1F90F}\u{1F918}-\u{1F91F}\u{1F926}\u{1F930}-\u{1F939}\u{1F93C}-\u{1F93E}\u{1F977}\u{1F9B5}-\u{1F9B6}\u{1F9B8}-\u{1F9B9}\u{1F9BB}\u{1F9CD}-\u{1F9CF}\u{1F9D1}-\u{1F9DD}]'
  r'(?:\u{1F3FB}|\u{1F3FC}|\u{1F3FD}|\u{1F3FE}|\u{1F3FF})?'
  r'(?:\u200D[\u2640\u2642]\uFE0F?)?'
  r'|'
  // Standard emoji (most common)
  r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]'
  r'(?:\uFE0F)?'
  r'(?:\u200D[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]\uFE0F?)*'
  r'|'
  // Miscellaneous symbols
  r'[\u{2300}-\u{23FF}\u{2B50}\u{2B55}\u{203C}\u{2049}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}]'
  r'\uFE0F?'
  r')',
  unicode: true,
);

/// Simplified regex for common emojis (faster but less complete)
final RegExp simpleEmojiRegex = RegExp(
  r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]'
  r'(?:[\u{1F3FB}-\u{1F3FF}])?'
  r'(?:\u{FE0F})?'
  r'(?:\u{200D}[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}])*',
  unicode: true,
);

/// Check if a string contains any emoji characters
bool containsEmoji(String text) {
  return emojiRegex.hasMatch(text);
}

/// Find all emoji matches in a string
Iterable<RegExpMatch> findEmojis(String text) {
  return emojiRegex.allMatches(text);
}

/// Convert an emoji character to its codepoint representation
/// e.g., "😀" -> "1F600" or "👨‍👩‍👧" -> "1F468-200D-1F469-200D-1F467"
String emojiToCodepoint(String emoji) {
  return emoji.runes
      .map((r) => r.toRadixString(16).toUpperCase().padLeft(4, '0'))
      .join('-');
}

/// Convert a codepoint representation to emoji character
/// e.g., "1F600" -> "😀"
String codepointToEmoji(String codepoint) {
  try {
    return String.fromCharCodes(
      codepoint.split('-').map((c) => int.parse(c, radix: 16)),
    );
  } catch (e) {
    return codepoint;
  }
}

/// Split text into segments of plain text and emojis
/// Returns a list of EmojiSegment objects
List<EmojiSegment> splitTextWithEmojis(String text) {
  final segments = <EmojiSegment>[];
  int lastEnd = 0;

  for (final match in emojiRegex.allMatches(text)) {
    // Add text before emoji
    if (match.start > lastEnd) {
      segments.add(EmojiSegment(
        text: text.substring(lastEnd, match.start),
        isEmoji: false,
      ));
    }

    // Add emoji
    segments.add(EmojiSegment(
      text: match.group(0)!,
      isEmoji: true,
      codepoint: emojiToCodepoint(match.group(0)!),
    ));

    lastEnd = match.end;
  }

  // Add remaining text
  if (lastEnd < text.length) {
    segments.add(EmojiSegment(
      text: text.substring(lastEnd),
      isEmoji: false,
    ));
  }

  return segments;
}

/// Represents a segment of text that may or may not be an emoji
class EmojiSegment {
  final String text;
  final bool isEmoji;
  final String? codepoint;

  const EmojiSegment({
    required this.text,
    required this.isEmoji,
    this.codepoint,
  });

  @override
  String toString() => 'EmojiSegment(text: $text, isEmoji: $isEmoji)';
}

/// Count the number of emojis in a string
int countEmojis(String text) {
  return emojiRegex.allMatches(text).length;
}

/// Check if a string consists only of emojis (no other text)
bool isOnlyEmojis(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;

  // Remove all emojis and whitespace, check if anything remains
  final withoutEmojis = trimmed.replaceAll(emojiRegex, '').replaceAll(RegExp(r'\s'), '');
  return withoutEmojis.isEmpty;
}

/// Get the number of emojis if text is only emojis, otherwise return 0
/// Useful for determining if message should use large emoji display
int getOnlyEmojiCount(String text) {
  if (!isOnlyEmojis(text)) return 0;
  return countEmojis(text);
}
