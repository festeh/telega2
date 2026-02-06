/// Emoji category enumeration for picker organization
enum EmojiCategory {
  recent('Recent', '🕐'),
  smileys('Smileys & Emotion', '😀'),
  people('People & Body', '👤'),
  animals('Animals & Nature', '🐱'),
  food('Food & Drink', '🍔'),
  travel('Travel & Places', '✈️'),
  activities('Activities', '⚽'),
  objects('Objects', '💡'),
  symbols('Symbols', '♠️'),
  flags('Flags', '🏁');

  final String displayName;
  final String icon;

  const EmojiCategory(this.displayName, this.icon);
}

/// Represents a single emoji with its rendering assets
class Emoji {
  final String codepoint;
  final String name;
  final EmojiCategory category;
  final List<String> shortcodes;
  final bool skinToneSupport;
  final bool hasAnimation;
  String? staticAssetPath;
  String? animatedAssetPath;
  int? tdlibFileId;

  Emoji({
    required this.codepoint,
    required this.name,
    required this.category,
    this.shortcodes = const [],
    this.skinToneSupport = false,
    this.hasAnimation = false,
    this.staticAssetPath,
    this.animatedAssetPath,
    this.tdlibFileId,
  });

  /// Convert codepoint string to actual emoji character
  /// e.g., "1F600" -> "😀" or "1F468-200D-1F469-200D-1F467" -> "👨‍👩‍👧"
  String get char {
    try {
      return String.fromCharCodes(
        codepoint.split('-').map((c) => int.parse(c, radix: 16)),
      );
    } catch (e) {
      return codepoint; // Return as-is if parsing fails
    }
  }

  /// Check if this emoji has a cached asset available
  bool get hasCachedAsset =>
      staticAssetPath != null || animatedAssetPath != null;

  /// Get the best available asset path (prefer animated if available)
  String? get bestAssetPath => animatedAssetPath ?? staticAssetPath;

  Emoji copyWith({
    String? codepoint,
    String? name,
    EmojiCategory? category,
    List<String>? shortcodes,
    bool? skinToneSupport,
    bool? hasAnimation,
    String? staticAssetPath,
    String? animatedAssetPath,
    int? tdlibFileId,
  }) {
    return Emoji(
      codepoint: codepoint ?? this.codepoint,
      name: name ?? this.name,
      category: category ?? this.category,
      shortcodes: shortcodes ?? this.shortcodes,
      skinToneSupport: skinToneSupport ?? this.skinToneSupport,
      hasAnimation: hasAnimation ?? this.hasAnimation,
      staticAssetPath: staticAssetPath ?? this.staticAssetPath,
      animatedAssetPath: animatedAssetPath ?? this.animatedAssetPath,
      tdlibFileId: tdlibFileId ?? this.tdlibFileId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Emoji &&
          runtimeType == other.runtimeType &&
          codepoint == other.codepoint;

  @override
  int get hashCode => codepoint.hashCode;

  @override
  String toString() => 'Emoji($codepoint, $name)';
}

/// Tracks recently used emojis for the picker
class RecentEmoji {
  final String codepoint;
  int useCount;
  DateTime lastUsed;

  RecentEmoji({required this.codepoint, this.useCount = 1, DateTime? lastUsed})
    : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'codepoint': codepoint,
    'useCount': useCount,
    'lastUsed': lastUsed.toIso8601String(),
  };

  factory RecentEmoji.fromJson(Map<String, dynamic> json) => RecentEmoji(
    codepoint: json['codepoint'] as String,
    useCount: json['useCount'] as int? ?? 1,
    lastUsed: json['lastUsed'] != null
        ? DateTime.parse(json['lastUsed'] as String)
        : DateTime.now(),
  );
}
