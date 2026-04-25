import 'package:telega2/domain/entities/emoji.dart';

/// Repository interface for the emoji picker (categories, search, recents).
/// Rendering does not go through this — it uses [EmojiCatalog] + [EmojiAtlas]
/// directly via the [TelegramEmojiWidget].
abstract class EmojiRepository {
  Future<void> initialize();

  Future<List<Emoji>> getEmojisByCategory(EmojiCategory category);

  Future<Emoji?> getEmoji(String codepoint);

  Future<Emoji?> getEmojiByChar(String char);

  Future<List<Emoji>> searchEmojis(String query);

  Future<List<Emoji>> getRecentEmojis({int limit = 30});

  Future<void> recordEmojiUsage(String codepoint);
}
