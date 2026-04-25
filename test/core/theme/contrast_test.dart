import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telega2/core/theme/appearance.dart';

const _darkSurface = Color(0xFF1C1C1E);
const _wcagAA = 4.5;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final brighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (brighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AccentPreset contrast on dark surface', () {
    for (final preset in AccentPreset.values) {
      test('${preset.name} ≥ 4.5:1 on #1C1C1E', () {
        final ratio = _contrast(preset.color, _darkSurface);
        expect(
          ratio,
          greaterThanOrEqualTo(_wcagAA),
          reason:
              '${preset.name} (${preset.color}) contrast = '
              '${ratio.toStringAsFixed(2)}:1 — must be ≥ $_wcagAA',
        );
      });
    }
  });
}
