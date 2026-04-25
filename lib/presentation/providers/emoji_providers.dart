import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telega2/core/emoji/emoji_atlas.dart';
import 'package:telega2/data/repositories/emoji_repository_impl.dart';
import 'package:telega2/domain/entities/emoji.dart';
import 'package:telega2/domain/repositories/emoji_repository.dart';

final emojiRepositoryProvider = Provider<EmojiRepository>((ref) {
  return EmojiRepositoryImpl();
});

final emojisByCategoryProvider =
    FutureProvider.family<List<Emoji>, EmojiCategory>((ref, category) async {
  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  return repo.getEmojisByCategory(category);
});

final recentEmojisProvider = FutureProvider<List<Emoji>>((ref) async {
  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  return repo.getRecentEmojis();
});

final emojiSearchProvider =
    FutureProvider.family<List<Emoji>, String>((ref, query) async {
  final repo = ref.watch(emojiRepositoryProvider);
  await repo.initialize();
  return repo.searchEmojis(query);
});

/// Decoded WEBP atlas sheet for a given sprite index (0..7).
final emojiSheetProvider =
    FutureProvider.family<ui.Image, int>((ref, sprite) {
  return EmojiAtlas.sheet(sprite);
});
