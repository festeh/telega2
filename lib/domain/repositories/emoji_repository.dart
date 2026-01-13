import 'package:telega2/domain/entities/emoji.dart';

/// Repository interface for emoji asset management
abstract class EmojiRepository {
  /// Get all emojis in a category
  Future<List<Emoji>> getEmojisByCategory(EmojiCategory category);

  /// Get emoji by codepoint
  Future<Emoji?> getEmoji(String codepoint);

  /// Get emoji by character (unicode string)
  Future<Emoji?> getEmojiByChar(String char);

  /// Search emojis by name or shortcode
  Future<List<Emoji>> searchEmojis(String query);

  /// Get recent/frequently used emojis
  Future<List<Emoji>> getRecentEmojis({int limit = 30});

  /// Record emoji usage (updates recent list)
  Future<void> recordEmojiUsage(String codepoint);

  /// Get cached asset path for emoji (downloads if needed)
  /// Returns null if asset not available (use native fallback)
  Future<String?> getEmojiAssetPath(String codepoint, {bool animated = false});

  /// Preload common emojis into cache
  Future<void> preloadCommonEmojis();

  /// Get current cache size in bytes
  int get cacheSize;

  /// Clear emoji cache
  Future<void> clearCache();

  /// Initialize the repository
  Future<void> initialize();
}
