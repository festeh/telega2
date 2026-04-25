import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telega2/core/emoji/emoji_catalog.dart';
import 'package:telega2/core/logging/app_logger.dart';
import 'package:telega2/presentation/providers/emoji_providers.dart';

final _logger = AppLogger.instance;
final Set<String> _missLogged = <String>{};

class TelegramEmojiWidget extends ConsumerWidget {
  const TelegramEmojiWidget({
    super.key,
    required this.emoji,
    this.size = 24.0,
    this.animated = true,
    this.onTap,
  });

  final String emoji;
  final double size;
  final bool animated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tile = EmojiCatalog.find(emoji);
    if (tile == null) {
      if (_missLogged.add(emoji)) {
        final codepoints = emoji.runes
            .map((r) => 'U+${r.toRadixString(16).toUpperCase()}')
            .join(' ');
        _logger.warning('emoji.catalog.miss emoji="$emoji" codepoints=$codepoints');
      }
      return SizedBox(width: size, height: size);
    }

    final sheet = ref.watch(emojiSheetProvider(tile.sprite));
    final body = sheet.when(
      data: (img) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _EmojiTilePainter(image: img, tile: tile),
        ),
      ),
      loading: () => SizedBox(width: size, height: size),
      error: (e, st) {
        _logger.error(
          'emoji.atlas.load_failed sprite=${tile.sprite}',
          error: e,
          stackTrace: st,
        );
        return SizedBox(width: size, height: size);
      },
    );

    if (onTap == null) return body;
    return GestureDetector(onTap: onTap, child: body);
  }
}

class _EmojiTilePainter extends CustomPainter {
  _EmojiTilePainter({required this.image, required this.tile});

  final ui.Image image;
  final EmojiTile tile;

  static final Paint _paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      tile.col * kEmojiTilePx.toDouble(),
      tile.row * kEmojiTilePx.toDouble(),
      kEmojiTilePx.toDouble(),
      kEmojiTilePx.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, _paint);
  }

  @override
  bool shouldRepaint(covariant _EmojiTilePainter old) {
    return old.image != image ||
        old.tile.sprite != tile.sprite ||
        old.tile.row != tile.row ||
        old.tile.col != tile.col;
  }
}

/// Static-context (non-Riverpod) wrapper retained for legacy call sites
/// that pre-resolve the asset path. The new pipeline ignores [assetPath]
/// and always renders through the catalog.
class StaticEmojiWidget extends StatelessWidget {
  const StaticEmojiWidget({
    super.key,
    required this.emoji,
    this.size = 24.0,
    this.assetPath,
    this.animated = true,
  });

  final String emoji;
  final double size;
  final String? assetPath;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TelegramEmojiWidget(
        emoji: emoji,
        size: size,
        animated: animated,
      ),
    );
  }
}
