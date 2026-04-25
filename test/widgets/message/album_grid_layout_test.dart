import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telega2/widgets/message/album_grid.dart';

void main() {
  const maxWidth = 250.0;

  /// Pumps an [AlbumGrid] with [n] keyed cells inside a fixed-width root,
  /// so we can read each cell's resolved size from the widget tree.
  Future<List<Size>> pumpGrid(WidgetTester tester, int n) async {
    final keys = [for (var i = 0; i < n; i++) ValueKey('cell-$i')];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: maxWidth,
            child: AlbumGrid(
              maxWidth: maxWidth,
              cells: [
                for (var i = 0; i < n; i++)
                  Container(key: keys[i], color: const Color(0xFF000000)),
              ],
            ),
          ),
        ),
      ),
    );
    return keys.map((k) => tester.getSize(find.byKey(k))).toList();
  }

  testWidgets('N=2 — two equal columns', (tester) async {
    final sizes = await pumpGrid(tester, 2);
    expect(sizes.length, 2);
    // Each cell is roughly half the width minus the gap.
    final expected = (maxWidth - 2.0) / 2;
    for (final s in sizes) {
      expect(s.width, closeTo(expected, 0.5));
    }
  });

  testWidgets('N=3 — left big + two stacked right', (tester) async {
    final sizes = await pumpGrid(tester, 3);
    expect(sizes.length, 3);
    // Big-left cell wider than each right cell.
    expect(sizes[0].width, greaterThan(sizes[1].width));
    expect(sizes[1].width, closeTo(sizes[2].width, 0.5));
    expect(sizes[1].height, closeTo(sizes[2].height, 0.5));
  });

  testWidgets('N=4 — 2x2 grid', (tester) async {
    final sizes = await pumpGrid(tester, 4);
    expect(sizes.length, 4);
    // All four cells equal in width and height.
    for (var i = 1; i < sizes.length; i++) {
      expect(sizes[i].width, closeTo(sizes[0].width, 0.5));
      expect(sizes[i].height, closeTo(sizes[0].height, 0.5));
    }
  });

  testWidgets('N=5 — 2 top, 3 bottom; top cells wider than bottom', (
    tester,
  ) async {
    final sizes = await pumpGrid(tester, 5);
    expect(sizes.length, 5);
    // Top row (cells 0, 1) cells are wider than bottom row (2, 3, 4).
    expect(sizes[0].width, greaterThan(sizes[2].width));
    expect(sizes[1].width, closeTo(sizes[0].width, 0.5));
    expect(sizes[3].width, closeTo(sizes[2].width, 0.5));
    expect(sizes[4].width, closeTo(sizes[2].width, 0.5));
  });

  testWidgets('N=6 — 2x3 grid, all cells equal', (tester) async {
    final sizes = await pumpGrid(tester, 6);
    expect(sizes.length, 6);
    for (var i = 1; i < sizes.length; i++) {
      expect(sizes[i].width, closeTo(sizes[0].width, 0.5));
      expect(sizes[i].height, closeTo(sizes[0].height, 0.5));
    }
  });

  testWidgets('N=7..10 — 3-column flow with last row possibly partial', (
    tester,
  ) async {
    for (var n = 7; n <= 10; n++) {
      final sizes = await pumpGrid(tester, n);
      expect(sizes.length, n, reason: 'N=$n');
      // All cells uniform.
      for (var i = 1; i < sizes.length; i++) {
        expect(sizes[i].width, closeTo(sizes[0].width, 0.5), reason: 'N=$n');
      }
    }
  });
}
