import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:telega2/core/emoji/emoji_asset_manager.dart';
import 'package:telega2/domain/entities/emoji.dart';
import 'package:telega2/domain/repositories/emoji_repository.dart';

/// Implementation of EmojiRepository using EmojiAssetManager
class EmojiRepositoryImpl implements EmojiRepository {
  static const String _recentEmojisKey = 'recent_emojis';
  static const int _maxRecentEmojis = 50;

  final EmojiAssetManager _assetManager;
  final List<RecentEmoji> _recentEmojis = [];
  bool _initialized = false;

  EmojiRepositoryImpl({EmojiAssetManager? assetManager})
    : _assetManager = assetManager ?? EmojiAssetManager();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await _assetManager.initialize();
    await _loadRecentEmojis();
    _initialized = true;
  }

  @override
  Future<List<Emoji>> getEmojisByCategory(EmojiCategory category) async {
    await _ensureInitialized();

    if (category == EmojiCategory.recent) {
      return getRecentEmojis();
    }

    return _assetManager.getEmojisByCategory(category);
  }

  @override
  Future<Emoji?> getEmoji(String codepoint) async {
    await _ensureInitialized();
    return _assetManager.getEmoji(codepoint);
  }

  @override
  Future<Emoji?> getEmojiByChar(String char) async {
    await _ensureInitialized();
    return _assetManager.getEmojiByChar(char);
  }

  @override
  Future<List<Emoji>> searchEmojis(String query) async {
    await _ensureInitialized();

    if (query.isEmpty) return [];
    return _assetManager.searchEmojis(query);
  }

  @override
  Future<List<Emoji>> getRecentEmojis({int limit = 30}) async {
    await _ensureInitialized();

    final recentCodepoints = _recentEmojis
        .take(limit)
        .map((r) => r.codepoint)
        .toList();

    final emojis = <Emoji>[];
    for (final codepoint in recentCodepoints) {
      final emoji = _assetManager.getEmoji(codepoint);
      if (emoji != null) {
        emojis.add(emoji);
      }
    }

    return emojis;
  }

  @override
  Future<void> recordEmojiUsage(String codepoint) async {
    await _ensureInitialized();

    // Find existing or create new
    final existingIndex = _recentEmojis.indexWhere(
      (r) => r.codepoint == codepoint,
    );

    if (existingIndex >= 0) {
      // Update existing
      final existing = _recentEmojis.removeAt(existingIndex);
      existing.useCount++;
      existing.lastUsed = DateTime.now();
      _recentEmojis.insert(0, existing);
    } else {
      // Add new
      _recentEmojis.insert(0, RecentEmoji(codepoint: codepoint));
    }

    // Trim to max size
    while (_recentEmojis.length > _maxRecentEmojis) {
      _recentEmojis.removeLast();
    }

    await _saveRecentEmojis();
  }

  @override
  Future<String?> getEmojiAssetPath(
    String codepoint, {
    bool animated = false,
  }) async {
    await _ensureInitialized();
    return _assetManager.getEmojiAssetPath(codepoint, animated: animated);
  }

  @override
  Future<void> preloadCommonEmojis() async {
    await _ensureInitialized();
    await _assetManager.preloadCommonEmojis();
  }

  @override
  int get cacheSize => _assetManager.cacheSize;

  @override
  Future<void> clearCache() async {
    await _assetManager.clearCache();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> _loadRecentEmojis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentEmojisKey);
      if (jsonString == null) return;

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      _recentEmojis.clear();
      for (final item in jsonList) {
        _recentEmojis.add(RecentEmoji.fromJson(item as Map<String, dynamic>));
      }
    } catch (e) {
      // Ignore errors, start with empty list
      _recentEmojis.clear();
    }
  }

  Future<void> _saveRecentEmojis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _recentEmojis.map((r) => r.toJson()).toList();
      await prefs.setString(_recentEmojisKey, jsonEncode(jsonList));
    } catch (e) {
      // Ignore save errors
    }
  }
}
