import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata for a cached emoji asset
class EmojiCacheEntry {
  final String codepoint;
  String? staticPath;
  String? animatedPath;
  DateTime lastUsed;
  final DateTime downloadedAt;
  final int fileSize;

  EmojiCacheEntry({
    required this.codepoint,
    this.staticPath,
    this.animatedPath,
    DateTime? lastUsed,
    DateTime? downloadedAt,
    this.fileSize = 0,
  })  : lastUsed = lastUsed ?? DateTime.now(),
        downloadedAt = downloadedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'codepoint': codepoint,
        'staticPath': staticPath,
        'animatedPath': animatedPath,
        'lastUsed': lastUsed.toIso8601String(),
        'downloadedAt': downloadedAt.toIso8601String(),
        'fileSize': fileSize,
      };

  factory EmojiCacheEntry.fromJson(Map<String, dynamic> json) =>
      EmojiCacheEntry(
        codepoint: json['codepoint'] as String,
        staticPath: json['staticPath'] as String?,
        animatedPath: json['animatedPath'] as String?,
        lastUsed: json['lastUsed'] != null
            ? DateTime.parse(json['lastUsed'] as String)
            : null,
        downloadedAt: json['downloadedAt'] != null
            ? DateTime.parse(json['downloadedAt'] as String)
            : null,
        fileSize: json['fileSize'] as int? ?? 0,
      );
}

/// LRU cache for emoji assets
class EmojiCache {
  static const String _metadataKey = 'emoji_cache_metadata';
  static const int defaultMaxSizeBytes = 50 * 1024 * 1024; // 50MB

  final int maxSizeBytes;
  final Map<String, EmojiCacheEntry> _entries = {};
  int _totalSize = 0;
  Directory? _cacheDir;
  bool _initialized = false;

  EmojiCache({this.maxSizeBytes = defaultMaxSizeBytes});

  /// Initialize the cache - must be called before use
  Future<void> initialize() async {
    if (_initialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/emoji_cache');

    // Create cache directories
    await Directory('${_cacheDir!.path}/static').create(recursive: true);
    await Directory('${_cacheDir!.path}/animated').create(recursive: true);

    // Load metadata from SharedPreferences
    await _loadMetadata();
    _initialized = true;
  }

  /// Get cache directory path
  String get cachePath => _cacheDir?.path ?? '';

  /// Get current cache size in bytes
  int get totalSize => _totalSize;

  /// Get number of cached emojis
  int get entryCount => _entries.length;

  /// Check if an emoji is cached
  bool isCached(String codepoint) => _entries.containsKey(codepoint);

  /// Get cached path for an emoji
  Future<String?> getCachedPath(String codepoint, {bool animated = false}) async {
    await _ensureInitialized();

    final entry = _entries[codepoint];
    if (entry == null) return null;

    // Update LRU timestamp
    entry.lastUsed = DateTime.now();
    await _saveMetadata();

    return animated ? entry.animatedPath : entry.staticPath;
  }

  /// Cache an emoji asset
  Future<void> cacheAsset(
    String codepoint,
    String sourcePath, {
    bool animated = false,
  }) async {
    await _ensureInitialized();

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return;

    final fileSize = await sourceFile.length();
    await _ensureCacheSpace(fileSize);

    final extension = animated ? 'tgs' : 'webp';
    final subDir = animated ? 'animated' : 'static';
    final destPath = '${_cacheDir!.path}/$subDir/$codepoint.$extension';

    await sourceFile.copy(destPath);

    // Update or create entry
    final existingEntry = _entries[codepoint];
    if (existingEntry != null) {
      if (animated) {
        existingEntry.animatedPath = destPath;
      } else {
        existingEntry.staticPath = destPath;
      }
      existingEntry.lastUsed = DateTime.now();
    } else {
      _entries[codepoint] = EmojiCacheEntry(
        codepoint: codepoint,
        staticPath: animated ? null : destPath,
        animatedPath: animated ? destPath : null,
        fileSize: fileSize,
      );
    }

    _totalSize += fileSize;
    await _saveMetadata();
  }

  /// Register an external path for an emoji (e.g., TDLib-downloaded file)
  /// Does not copy the file, just tracks the path reference
  Future<void> registerPath(
    String codepoint,
    String path, {
    bool animated = false,
  }) async {
    await _ensureInitialized();

    final file = File(path);
    final fileSize = await file.exists() ? await file.length() : 0;

    // Update or create entry
    final existingEntry = _entries[codepoint];
    if (existingEntry != null) {
      if (animated) {
        existingEntry.animatedPath = path;
      } else {
        existingEntry.staticPath = path;
      }
      existingEntry.lastUsed = DateTime.now();
    } else {
      _entries[codepoint] = EmojiCacheEntry(
        codepoint: codepoint,
        staticPath: animated ? null : path,
        animatedPath: animated ? path : null,
        fileSize: fileSize,
      );
    }

    await _saveMetadata();
  }

  /// Evict an emoji from cache
  Future<void> evict(String codepoint) async {
    await _ensureInitialized();

    final entry = _entries[codepoint];
    if (entry == null) return;

    // Delete files
    if (entry.staticPath != null) {
      final file = File(entry.staticPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    if (entry.animatedPath != null) {
      final file = File(entry.animatedPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _totalSize -= entry.fileSize;
    _entries.remove(codepoint);
    await _saveMetadata();
  }

  /// Clear entire cache
  Future<void> clear() async {
    await _ensureInitialized();

    // Delete all files in cache directories
    final staticDir = Directory('${_cacheDir!.path}/static');
    final animatedDir = Directory('${_cacheDir!.path}/animated');

    if (await staticDir.exists()) {
      await for (final file in staticDir.list()) {
        if (file is File) await file.delete();
      }
    }
    if (await animatedDir.exists()) {
      await for (final file in animatedDir.list()) {
        if (file is File) await file.delete();
      }
    }

    _entries.clear();
    _totalSize = 0;
    await _saveMetadata();
  }

  /// Ensure there's enough space for a new file
  Future<void> _ensureCacheSpace(int neededBytes) async {
    while (_totalSize + neededBytes > maxSizeBytes && _entries.isNotEmpty) {
      // Find oldest entry (LRU)
      final oldest = _entries.values.reduce(
        (a, b) => a.lastUsed.isBefore(b.lastUsed) ? a : b,
      );
      await evict(oldest.codepoint);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> _loadMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_metadataKey);
      if (jsonString == null) return;

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      _totalSize = data['totalSize'] as int? ?? 0;

      final entriesJson = data['entries'] as Map<String, dynamic>? ?? {};
      for (final entry in entriesJson.entries) {
        _entries[entry.key] = EmojiCacheEntry.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }

      // Validate cached files still exist
      await _validateCacheEntries();
    } catch (e) {
      // If metadata is corrupted, start fresh
      _entries.clear();
      _totalSize = 0;
    }
  }

  Future<void> _saveMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'version': 1,
      'totalSize': _totalSize,
      'maxSize': maxSizeBytes,
      'entries': _entries.map((k, v) => MapEntry(k, v.toJson())),
    };
    await prefs.setString(_metadataKey, jsonEncode(data));
  }

  Future<void> _validateCacheEntries() async {
    final toRemove = <String>[];

    for (final entry in _entries.entries) {
      bool valid = false;

      if (entry.value.staticPath != null) {
        valid = await File(entry.value.staticPath!).exists();
      }
      if (entry.value.animatedPath != null) {
        valid = valid || await File(entry.value.animatedPath!).exists();
      }

      if (!valid) {
        toRemove.add(entry.key);
      }
    }

    for (final codepoint in toRemove) {
      _entries.remove(codepoint);
    }

    // Recalculate total size
    _totalSize = 0;
    for (final entry in _entries.values) {
      _totalSize += entry.fileSize;
    }
  }
}
