// One-shot codegen: parses assets/emoji/emoji.txt and emits
// lib/core/emoji/emoji_catalog.g.dart with a const Map of canonical emoji
// strings to (sprite, row, col) tile positions inside the 8 vendored atlases.
//
// Mirrors tdesktop's codegen pipeline:
//   - Telegram/codegen/codegen/emoji/data_read.cpp (file parsing)
//   - Telegram/codegen/codegen/emoji/data.cpp::PrepareData + appendCategory
//     (skin-tone expansion → flat list)
//   - Telegram/codegen/codegen/emoji/generator.cpp (32×16×8 atlas packing)
//
// Run: `dart run tool/emoji/generate_catalog.dart`.
// Re-run whenever assets/emoji/emoji.txt is bumped from tdesktop.

// ignore_for_file: avoid_print

import 'dart:io';

const int kPostfix = 0xFE0F;
const int kJoiner = 0x200D;
const int kColorMask = 0xD83CDFFB;
const List<int> kColors = [
  0xD83CDFFB,
  0xD83CDFFC,
  0xD83CDFFD,
  0xD83CDFFE,
  0xD83CDFFF,
];

const int kEmojiInRow = 32;
const int kEmojiRowsInFile = 16;
const int kPerSheet = kEmojiInRow * kEmojiRowsInFile;
const int kSheetCount = 8;

typedef InputId = List<int>;

InputId stringToInputId(String s) {
  final result = <int>[];
  for (var i = 0; i < s.length; i++) {
    final unit = s.codeUnitAt(i);
    if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < s.length) {
      final low = s.codeUnitAt(i + 1);
      result.add((unit << 16) | low);
      i++;
    } else {
      result.add(unit);
    }
  }
  return result;
}

void _writeCode(StringBuffer sb, int code) {
  if (code > 0xFFFF) {
    sb.writeCharCode((code >> 16) & 0xFFFF);
    sb.writeCharCode(code & 0xFFFF);
  } else {
    sb.writeCharCode(code);
  }
}

String inputIdToString(InputId id) {
  final sb = StringBuffer();
  for (final code in id) {
    _writeCode(sb, code);
  }
  return sb.toString();
}

String bareIdFromInput(InputId id) {
  final sb = StringBuffer();
  for (final code in id) {
    if (code == kPostfix) continue;
    _writeCode(sb, code);
  }
  return sb.toString();
}

class EmojiFile {
  final List<List<List<List<String>>>> sections;
  EmojiFile(this.sections);
}

EmojiFile parseEmojiTxt(String text) {
  final sectionTexts = text.split(RegExp(r'(?:={8,}|-{8,})'));
  final result = <List<List<List<String>>>>[];
  for (final sectionText in sectionTexts) {
    final partTexts = sectionText.split(RegExp(r'\r?\n[ \t]*\r?\n'));
    final section = <List<List<String>>>[];
    for (final partText in partTexts) {
      final lineTexts = partText.split(RegExp(r'\r?\n'));
      final part = <List<String>>[];
      for (final lineText in lineTexts) {
        if (lineText.trim().isEmpty) continue;
        // Tdesktop's ReadString splits on commas, then takes only the FIRST
        // pair of quotes per comma-separated chunk. Anything after the closing
        // quote (e.g. a typo like `"🪉""🎻"` missing a comma) is dropped.
        // Mirror that exactly so atlas positions line up.
        final strings = <String>[];
        for (final chunk in lineText.split(',')) {
          final start = chunk.indexOf('"');
          if (start < 0) continue;
          final end = chunk.indexOf('"', start + 1);
          if (end <= start) continue;
          strings.add(chunk.substring(start + 1, end));
        }
        if (strings.isNotEmpty) part.add(strings);
      }
      if (part.isNotEmpty) section.add(part);
    }
    if (section.isNotEmpty) result.add(section);
  }
  return EmojiFile(result);
}

// === Pulled from tdesktop data.cpp ===

List<String>? _findColoredLine(EmojiFile file, String colored) {
  // Walk file[0] (8 categories). Each line is a colored sequence's variants:
  // [base, base+lightSkin, base+mediumLight, ..., base+dark].
  // Match the first element.
  for (final part in file.sections[0]) {
    for (final line in part) {
      if (line.isNotEmpty && line[0] == colored) return line;
    }
  }
  return null;
}

InputId? _findFirstColored(EmojiFile file, String colored) {
  final line = _findColoredLine(file, colored);
  if (line == null || line.length != 6) return null;
  return stringToInputId(line[1]);
}

class DoubleColored {
  final InputId original;
  final InputId same;
  final InputId different;
  DoubleColored(this.original, this.same, this.different);
}

DoubleColored? _findDoubleColored(EmojiFile file, String colored) {
  final line = _findColoredLine(file, colored);
  if (line == null || line.length != 26) return null;
  return DoubleColored(
    stringToInputId(line[0]),
    stringToInputId(line[1]),
    stringToInputId(line[2]),
  );
}

class InputData {
  final List<List<InputId>> categories;
  final List<InputId> other;
  final List<InputId> colored;
  final List<DoubleColored> doubleColored;
  InputData(this.categories, this.other, this.colored, this.doubleColored);
}

InputData readData(EmojiFile file) {
  if (file.sections.length < 3 ||
      file.sections[0].length != 8 ||
      file.sections[1].length > 8) {
    throw StateError('Wrong file parts: ${file.sections.length} sections, '
        '${file.sections[0].length} parts in section 0, '
        '${file.sections[1].length} in section 1');
  }

  final colored = <InputId>[];
  final coloredPart = file.sections[2][0];
  for (final line in coloredPart) {
    for (final s in line) {
      final firstColored = _findFirstColored(file, s);
      if (firstColored == null || firstColored.length < 2) {
        throw StateError('Bad colored emoji: $s');
      }
      colored.add(firstColored);
    }
  }

  final doubleColored = <DoubleColored>[];
  if (file.sections[2].length > 1) {
    for (final line in file.sections[2][1]) {
      for (final s in line) {
        final dc = _findDoubleColored(file, s);
        if (dc == null) {
          throw StateError('Bad double colored emoji: $s');
        }
        doubleColored.add(dc);
      }
    }
  }

  final categories = <List<InputId>>[];
  var index = 0;
  for (final section in file.sections[0]) {
    final first = section.first.first;
    List<List<String>>? replaced;
    for (final r in file.sections[1]) {
      if (r.first.first == first) {
        replaced = r;
        break;
      }
    }
    final use = replaced ?? section;
    while (categories.length <= index) {
      categories.add(<InputId>[]);
    }
    for (final line in use) {
      for (final s in line) {
        categories[index].add(stringToInputId(s));
      }
    }
    if (index + 1 < 8) index++;
  }

  final other = <InputId>[];
  if (file.sections.length > 3) {
    for (final part in file.sections[3]) {
      for (final line in part) {
        for (final s in line) {
          other.add(stringToInputId(s));
        }
      }
    }
  }

  return InputData(categories, other, colored, doubleColored);
}

Set<String> fillVariatedIds(List<InputId> colored) {
  final result = <String>{};
  for (final row in colored) {
    if (row.length < 2) {
      throw StateError('colored row too short');
    }
    final sb = StringBuffer();
    for (var i = 0; i < row.length; i++) {
      final code = row[i];
      if (i == 1) {
        if (code != kColorMask) {
          throw StateError('color must appear at index 1');
        }
        continue;
      }
      if (code == kColorMask) {
        throw StateError('color appears outside index 1');
      }
      if (code == kPostfix) continue;
      _writeCode(sb, code);
    }
    result.add(sb.toString());
  }
  return result;
}

Map<String, InputId> fillDoubleVariatedIds(List<DoubleColored> entries) {
  final result = <String, InputId>{};
  for (final e in entries) {
    final originalBare = bareIdFromInput(e.original);
    result[originalBare] = e.different;
  }
  return result;
}

class EmojiOut {
  final String key;          // canonical (FE0F-stripped) string
  final bool postfixed;
  final bool variated;
  EmojiOut(this.key, {required this.postfixed, required this.variated});
}

class _BuildState {
  final List<EmojiOut> list = [];
  final Map<String, int> map = {};
}

int? _addOne(_BuildState state, String bareId, EmojiOut entry) {
  final existing = state.map[bareId];
  if (existing != null) {
    final prior = state.list[existing];
    if (prior.postfixed != entry.postfixed) {
      throw StateError('postfixed mismatch for $bareId');
    }
    return existing;
  }
  final index = state.list.length;
  state.list.add(entry);
  state.map[bareId] = index;
  return index;
}

void _appendCategory(
  _BuildState state,
  List<InputId> category,
  Set<String> variatedIds,
  Map<String, InputId> doubleVariatedIds,
) {
  for (final id in category) {
    final bareId = bareIdFromInput(id);
    if (bareId.isEmpty) {
      throw StateError('empty emoji id');
    }
    var postfixed = false;
    var to = id.length;
    if (id.length == 2 && id.last == kPostfix) {
      postfixed = true;
      to = 1;
    }
    for (var i = 0; i < to; i++) {
      final code = id[i];
      if (kColors.contains(code)) {
        throw StateError('color in plain category emoji');
      }
    }

    final variated = variatedIds.contains(bareId);
    final entry = EmojiOut(
      bareId,
      postfixed: postfixed,
      variated: variated,
    );
    final baseIndex = _addOne(state, bareId, entry);
    if (baseIndex == null) continue;

    if (variated) {
      // Walk the original `id` once, splitting around the first character.
      var fromIdx = 0;
      if (id[fromIdx] == kPostfix) {
        throw StateError('bad first symbol in variated emoji');
      }
      final firstCode = id[fromIdx++];
      // tdesktop quirk: a few have two kPostfix; skip a leading second one.
      var postCount = 0;
      for (var i = fromIdx; i < id.length; i++) {
        if (id[i] == kPostfix) postCount++;
      }
      if (postCount == 2 && fromIdx < id.length && id[fromIdx] == kPostfix) {
        fromIdx++;
      }
      for (final color in kColors) {
        final coloredBareSb = StringBuffer();
        _writeCode(coloredBareSb, firstCode);
        _writeCode(coloredBareSb, color);
        for (var i = fromIdx; i < id.length; i++) {
          if (id[i] == kPostfix) continue;
          _writeCode(coloredBareSb, id[i]);
        }
        final coloredBare = coloredBareSb.toString();
        _addOne(
          state,
          coloredBare,
          EmojiOut(coloredBare, postfixed: false, variated: false),
        );
      }
      continue;
    }

    final different = doubleVariatedIds[bareId];
    if (different != null) {
      // 25 (color1, color2) combinations. tdesktop uses a fast path when
      // base is just two codepoints (e.g. 🤝): same-color variants reuse
      // base+color, different-color variants splice colors into `different`.
      final fastPath = bareId.runes.length == 1; // bareId after stripping FE0F
      for (final color1 in kColors) {
        for (final color2 in kColors) {
          final cb = StringBuffer();
          if (color1 == color2 && fastPath) {
            // base + color
            _writeCode(cb, id[0]);
            _writeCode(cb, color1);
          } else {
            // splice into `different`: color at idx 1 → color1, last code → color2
            for (var i = 0; i < different.length; i++) {
              var code = different[i];
              if (i == 1) {
                code = color1;
              } else if (i == different.length - 1) {
                code = color2;
              }
              if (code == kPostfix) continue;
              _writeCode(cb, code);
            }
          }
          final coloredBare = cb.toString();
          _addOne(
            state,
            coloredBare,
            EmojiOut(coloredBare, postfixed: false, variated: false),
          );
        }
      }
    }
  }
}

String _escapeForDart(String s) {
  final sb = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final unit = s.codeUnitAt(i);
    if (unit == 0x5C) {
      sb.write(r'\\');
    } else if (unit == 0x27) {
      sb.write(r"\'");
    } else if (unit == 0x0A) {
      sb.write(r'\n');
    } else if (unit == 0x0D) {
      sb.write(r'\r');
    } else if (unit < 0x20 || unit == 0x7F) {
      sb.write('\\u{${unit.toRadixString(16)}}');
    } else if (unit >= 0x20 && unit <= 0x7E) {
      sb.writeCharCode(unit);
    } else {
      sb.write('\\u{${unit.toRadixString(16)}}');
    }
  }
  return sb.toString();
}

void main(List<String> args) {
  final txt = File('assets/emoji/emoji.txt').readAsStringSync();
  final file = parseEmojiTxt(txt);
  final input = readData(file);

  print('parsed: '
      '${input.categories.length} categories, '
      '${input.categories.fold<int>(0, (a, b) => a + b.length)} category emojis, '
      '${input.other.length} other, '
      '${input.colored.length} colored, '
      '${input.doubleColored.length} double-colored');

  final variatedIds = fillVariatedIds(input.colored);
  final doubleVariatedIds = fillDoubleVariatedIds(input.doubleColored);

  final state = _BuildState();
  for (final cat in input.categories) {
    _appendCategory(state, cat, variatedIds, doubleVariatedIds);
  }
  _appendCategory(state, input.other, variatedIds, doubleVariatedIds);

  print('flat list: ${state.list.length} entries (max ${kSheetCount * kPerSheet})');
  if (state.list.length > kSheetCount * kPerSheet) {
    throw StateError('catalog overflows $kSheetCount atlas sheets');
  }

  final highestSprite = (state.list.length - 1) ~/ kPerSheet;
  print('highest sprite used: $highestSprite (atlases ship 0..${kSheetCount - 1})');

  final out = StringBuffer();
  out.writeln('// GENERATED — do not edit.');
  out.writeln('// Re-run: dart run tool/emoji/generate_catalog.dart');
  out.writeln('// Source: tdesktop emoji.txt + 32×16 packing per generator.cpp');
  out.writeln();
  out.writeln('class EmojiTile {');
  out.writeln('  final int sprite;');
  out.writeln('  final int row;');
  out.writeln('  final int col;');
  out.writeln('  final bool postfixed;');
  out.writeln('  const EmojiTile(this.sprite, this.row, this.col, this.postfixed);');
  out.writeln('}');
  out.writeln();
  out.writeln('const int kEmojiSheetCount = $kSheetCount;');
  out.writeln('const int kEmojiTilePx = 72;');
  out.writeln('const int kEmojiSheetCols = $kEmojiInRow;');
  out.writeln('const int kEmojiSheetRows = $kEmojiRowsInFile;');
  out.writeln();
  out.writeln('const Map<String, EmojiTile> kEmojiCatalog = {');
  for (var i = 0; i < state.list.length; i++) {
    final e = state.list[i];
    final sprite = i ~/ kPerSheet;
    final inSheet = i % kPerSheet;
    final row = inSheet ~/ kEmojiInRow;
    final col = inSheet % kEmojiInRow;
    final post = e.postfixed ? 'true' : 'false';
    out.writeln("  '${_escapeForDart(e.key)}': EmojiTile($sprite, $row, $col, $post),");
  }
  out.writeln('};');

  final outPath = 'lib/core/emoji/emoji_catalog.g.dart';
  File(outPath).writeAsStringSync(out.toString());
  print('wrote $outPath (${out.length} bytes)');
}
