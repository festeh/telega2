import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telega2/core/emoji/emoji_asset_manager.dart';
import 'package:telega2/data/repositories/emoji_repository_impl.dart';
import 'package:telega2/domain/entities/emoji.dart';
import 'package:telega2/domain/repositories/emoji_repository.dart';

/// Provides the emoji asset manager instance
final emojiAssetManagerProvider = Provider<EmojiAssetManager>((ref) {
  return EmojiAssetManager();
});

/// Provides the emoji repository instance
final emojiRepositoryProvider = Provider<EmojiRepository>((ref) {
  final assetManager = ref.watch(emojiAssetManagerProvider);
  return EmojiRepositoryImpl(assetManager: assetManager);
});

/// Provides emojis for a specific category
final emojisByCategoryProvider =
    FutureProvider.family<List<Emoji>, EmojiCategory>((ref, category) async {
      final repo = ref.watch(emojiRepositoryProvider);
      await repo.initialize();
      return repo.getEmojisByCategory(category);
    });

/// Provides recent emojis
final recentEmojisProvider = FutureProvider<List<Emoji>>((ref) async {
  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  return repo.getRecentEmojis();
});

/// Provides emoji search results
final emojiSearchProvider = FutureProvider.family<List<Emoji>, String>((
  ref,
  query,
) async {
  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  return repo.searchEmojis(query);
});

/// Provides asset path for a specific emoji
/// Parameter format: "codepoint:animated" e.g., "1F600:true" or "1F600:false"
final emojiAssetPathProvider = FutureProvider.family<String?, String>((
  ref,
  params,
) async {
  final parts = params.split(':');
  final codepoint = parts[0];
  final animated = parts.length > 1 && parts[1] == 'true';

  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  return repo.getEmojiAssetPath(codepoint, animated: animated);
});

/// Helper function to convert emoji character to codepoint string
String emojiCharToCodepoint(String char) {
  return char.runes.map((r) => r.toRadixString(16).toUpperCase()).join('-');
}
