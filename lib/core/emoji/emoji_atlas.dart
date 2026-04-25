import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:telega2/core/emoji/emoji_catalog.dart';

class EmojiAtlas {
  EmojiAtlas._();

  static final Map<int, Future<ui.Image>> _sheets = {};

  static Future<ui.Image> sheet(int sprite) {
    assert(sprite >= 0 && sprite < kEmojiSheetCount,
        'sprite $sprite out of range 0..${kEmojiSheetCount - 1}');
    return _sheets.putIfAbsent(sprite, () => _decode(sprite));
  }

  static Future<ui.Image> _decode(int sprite) async {
    final data = await rootBundle.load('assets/emoji/emoji_${sprite + 1}.webp');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
