import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telega2/core/emoji/emoji_asset_manager.dart';
import 'package:telega2/data/repositories/emoji_repository_impl.dart';
import 'package:telega2/domain/entities/emoji.dart';
import 'package:telega2/domain/repositories/emoji_repository.dart';
import 'package:telega2/presentation/providers/telegram_client_provider.dart';

/// Provides the emoji asset manager instance
/// Connected to TDLib for downloading animated emojis
final emojiAssetManagerProvider = Provider<EmojiAssetManager>((ref) {
  final assetManager = EmojiAssetManager();

  // Connect to TDLib for animated emoji downloads
  final telegramClient = ref.watch(telegramClientProvider);
  assetManager.setTelegramClient(telegramClient);

  return assetManager;
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
final emojiSearchProvider =
    FutureProvider.family<List<Emoji>, String>((ref, query) async {
  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  return repo.searchEmojis(query);
});

/// Provides asset path for a specific emoji
/// Parameter format: "codepoint:animated" e.g., "1F600:true" or "1F600:false"
final emojiAssetPathProvider =
    FutureProvider.family<String?, String>((ref, params) async {
  final parts = params.split(':');
  final codepoint = parts[0];
  final animated = parts.length > 1 && parts[1] == 'true';

  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  return repo.getEmojiAssetPath(codepoint, animated: animated);
});

/// Provider to record emoji usage
final recordEmojiUsageProvider =
    FutureProvider.family<void, String>((ref, codepoint) async {
  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  await repo.recordEmojiUsage(codepoint);
  // Invalidate recent emojis to refresh
  ref.invalidate(recentEmojisProvider);
});

/// Notifier for emoji repository state
class EmojiNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    final repo = ref.watch(emojiRepositoryProvider);
    await repo.initialize();
  }

  /// Record emoji usage and refresh recent list
  Future<void> recordUsage(String codepoint) async {
    final repo = ref.read(emojiRepositoryProvider);
    await repo.recordEmojiUsage(codepoint);
    ref.invalidate(recentEmojisProvider);
  }

  /// Clear emoji cache
  Future<void> clearCache() async {
    final repo = ref.read(emojiRepositoryProvider);
    await repo.clearCache();
  }

  /// Preload common emojis
  Future<void> preload() async {
    final repo = ref.read(emojiRepositoryProvider);
    await repo.preloadCommonEmojis();
  }
}

/// Provides the emoji notifier for state management
final emojiNotifierProvider =
    AsyncNotifierProvider<EmojiNotifier, void>(EmojiNotifier.new);

/// Helper function to convert emoji character to codepoint string
String emojiCharToCodepoint(String char) {
  return char.runes.map((r) => r.toRadixString(16).toUpperCase()).join('-');
}

/// Helper function to convert codepoint string to emoji character
String codepointToEmojiChar(String codepoint) {
  try {
    return String.fromCharCodes(
      codepoint.split('-').map((c) => int.parse(c, radix: 16)),
    );
  } catch (e) {
    return codepoint;
  }
}
