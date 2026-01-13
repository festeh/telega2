import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:telega2/core/logging/app_logger.dart';
import 'package:telega2/presentation/providers/emoji_providers.dart';

final _logger = AppLogger.instance;

/// Widget that renders a single emoji using Telegram-style custom assets
/// Uses TDLib for animated emojis or bundled assets for static emojis
class TelegramEmojiWidget extends ConsumerWidget {
  /// The emoji character to render (e.g., "😀")
  final String emoji;

  /// Size of the emoji in logical pixels
  final double size;

  /// Whether to play animations (for animated emojis)
  final bool animated;

  /// Optional tap callback
  final VoidCallback? onTap;

  const TelegramEmojiWidget({
    super.key,
    required this.emoji,
    this.size = 24.0,
    this.animated = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Convert emoji character to codepoint for asset lookup
    final codepoint = emojiCharToCodepoint(emoji);
    final assetKey = '$codepoint:${animated ? 'true' : 'false'}';

    final assetPath = ref.watch(emojiAssetPathProvider(assetKey));

    // Debug logging
    assetPath.whenData((path) {
      _logger.debug('Emoji asset: emoji="$emoji" codepoint=$codepoint path=$path');
    });

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: assetPath.when(
          data: (path) => _buildEmoji(path),
          loading: () => _buildLoading(),
          error: (_, __) => _buildError(),
        ),
      ),
    );
  }

  Widget _buildEmoji(String? path) {
    if (path == null) {
      _logger.debug('Emoji _buildEmoji: path is null');
      return _buildError();
    }

    final file = File(path);

    // Check file extension for animation type
    if (path.endsWith('.tgs') && animated) {
      return _buildLottieEmoji(file);
    } else if (path.endsWith('.webp') || path.endsWith('.png')) {
      return _buildImageEmoji(file);
    } else if (path.endsWith('.json')) {
      return _buildLottieEmoji(file);
    } else {
      _logger.debug('Emoji _buildEmoji: unknown extension for $path');
      return _buildError();
    }
  }

  Widget _buildLottieEmoji(File file) {
    // TGS files are gzip-compressed Lottie JSON
    if (file.path.endsWith('.tgs')) {
      return FutureBuilder<List<int>>(
        future: _decompressTgs(file),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Lottie.memory(
              Uint8List.fromList(snapshot.data!),
              width: size,
              height: size,
              fit: BoxFit.contain,
              repeat: true,
              animate: animated,
              errorBuilder: (context, error, stackTrace) {
                _logger.error('Lottie error for ${file.path}', error: error);
                return _buildError();
              },
            );
          }
          if (snapshot.hasError) {
            _logger.error('TGS decompress error for ${file.path}', error: snapshot.error);
            return _buildError();
          }
          return _buildLoading();
        },
      );
    }

    return Lottie.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      animate: animated,
      errorBuilder: (context, error, stackTrace) => _buildError(),
    );
  }

  Future<List<int>> _decompressTgs(File file) async {
    final bytes = await file.readAsBytes();
    return GZipCodec().decode(bytes);
  }

  Widget _buildImageEmoji(File file) {
    return Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        _logger.error('Emoji Image.file error for ${file.path}', error: error);
        return _buildError();
      },
    );
  }

  Widget _buildLoading() {
    return Center(
      child: SizedBox(
        width: size * 0.5,
        height: size * 0.5,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildError() {
    // Show a placeholder box when asset not available
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Static version of TelegramEmojiWidget for synchronous rendering
class StaticEmojiWidget extends StatelessWidget {
  final String emoji;
  final double size;
  final String? assetPath;
  final bool animated;

  const StaticEmojiWidget({
    super.key,
    required this.emoji,
    this.size = 24.0,
    this.assetPath,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) {
      return _buildPlaceholder();
    }

    final file = File(assetPath!);

    if (assetPath!.endsWith('.tgs') || assetPath!.endsWith('.json')) {
      return Lottie.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
        animate: animated,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
