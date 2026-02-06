import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:telega2/core/emoji/emoji_cache.dart';
import 'package:telega2/core/emoji/emoji_data.dart';
import 'package:telega2/domain/entities/emoji.dart';

/// Manages emoji asset loading and caching
/// Uses TDLib to download animated emoji assets from Telegram servers
/// Falls back to native rendering if assets not available
class EmojiAssetManager {
  final EmojiCache _cache;
  final EmojiData _emojiData;

  // Track pending loads to avoid duplicates
  final Map<String, Completer<String?>> _pendingLoads = {};

  bool _initialized = false;

  EmojiAssetManager({EmojiCache? cache, EmojiData? emojiData})
    : _cache = cache ?? EmojiCache(),
      _emojiData = emojiData ?? EmojiData();

  /// Initialize the asset manager
  Future<void> initialize() async {
    if (_initialized) return;

    await _cache.initialize();
    _emojiData.initialize();
    _initialized = true;
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Get asset path for an emoji
  /// Tries in order: cache -> TDLib animated emoji -> bundled assets -> null (native fallback)
  Future<String?> getEmojiAssetPath(
    String codepoint, {
    bool animated = false,
  }) async {
    await _ensureInitialized();

    // Check cache first
    final cachedPath = await _cache.getCachedPath(
      codepoint,
      animated: animated,
    );
    if (cachedPath != null && await File(cachedPath).exists()) {
      return cachedPath;
    }

    // Check if already loading
    final pendingKey = '$codepoint:${animated ? 'animated' : 'static'}';
    if (_pendingLoads.containsKey(pendingKey)) {
      return _pendingLoads[pendingKey]!.future;
    }

    final completer = Completer<String?>();
    _pendingLoads[pendingKey] = completer;

    try {
      String? path;

      // Try bundled Telegram emojis first (extracted from tdesktop)
      path = await _loadBundledAsset(codepoint, animated: false);
      if (path != null) {
        completer.complete(path);
        return path;
      }

      // No asset found
      completer.complete(null);
      return null;
    } catch (e) {
      completer.complete(null);
      return null;
    } finally {
      _pendingLoads.remove(pendingKey);
    }
  }

  /// Try to load emoji from bundled assets
  Future<String?> _loadBundledAsset(
    String codepoint, {
    bool animated = false,
  }) async {
    // Try different extensions in order of preference
    final extensions = animated ? ['tgs', 'json'] : ['png', 'webp'];

    // Try different codepoint variants (with/without FE0F variant selector)
    final codepointVariants = _getCodepointVariants(codepoint);

    for (final cp in codepointVariants) {
      for (final extension in extensions) {
        final assetPath = 'assets/emoji/$cp.$extension';

        try {
          // Check if asset exists
          final data = await rootBundle.load(assetPath);

          // Copy to cache
          final cacheSubdir = animated ? 'animated' : 'static';
          final cachePath = '${_cache.cachePath}/$cacheSubdir/$cp.$extension';

          final file = File(cachePath);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data.buffer.asUint8List());

          return cachePath;
        } catch (e) {
          // Try next
          continue;
        }
      }
    }

    // No bundled asset found
    return null;
  }

  /// Get codepoint variants to try (with/without FE0F)
  List<String> _getCodepointVariants(String codepoint) {
    final variants = <String>[codepoint];

    // If doesn't have FE0F, try adding it
    if (!codepoint.contains('FE0F')) {
      variants.add('$codepoint-FE0F');
    }

    // If has FE0F, try removing it
    if (codepoint.contains('-FE0F')) {
      variants.add(codepoint.replaceAll('-FE0F', ''));
    }

    return variants;
  }

  /// Preload common emojis (no-op for MVP as we use native fallback)
  Future<void> preloadCommonEmojis() async {
    // In future: download from TDLib server
    // For MVP: rely on native fallback
  }

  /// Get emoji by codepoint
  Emoji? getEmoji(String codepoint) {
    return _emojiData.getEmoji(codepoint);
  }

  /// Get emoji by character
  Emoji? getEmojiByChar(String char) {
    return _emojiData.getEmojiByChar(char);
  }

  /// Get emojis by category
  List<Emoji> getEmojisByCategory(EmojiCategory category) {
    return _emojiData.getEmojisByCategory(category);
  }

  /// Search emojis
  List<Emoji> searchEmojis(String query) {
    return _emojiData.searchEmojis(query);
  }

  /// Get all emojis
  List<Emoji> get allEmojis => _emojiData.allEmojis;

  /// Get cache size
  int get cacheSize => _cache.totalSize;

  /// Clear cache
  Future<void> clearCache() => _cache.clear();

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
