import 'package:flutter/material.dart';
import '../../core/constants/ui_constants.dart';

/// Lays out 2..10 media cells in a fixed-pattern tiled grid, bounded by
/// [maxWidth]. Cells are positioned tightly with a 2px hairline gap (matching
/// the official Telegram client's grouped-media gap).
///
/// Patterns by [cells.length]:
///   - 2 → one row, two equal columns
///   - 3 → big-left, two-stacked-right (60/40 split)
///   - 4 → 2×2 grid
///   - 5 → top row 2 cells, bottom row 3 cells (heights split 1.0 : 0.66)
///   - 6 → 2 rows × 3 cells
///   - 7..10 → 3-column flow with the last row possibly under-filled
class AlbumGrid extends StatelessWidget {
  final List<Widget> cells;
  final double maxWidth;
  final double gap;

  const AlbumGrid({
    super.key,
    required this.cells,
    this.maxWidth = MediaSize.maxWidth,
    this.gap = 2.0,
  })  : assert(cells.length >= 2),
        assert(cells.length <= 10);

  @override
  Widget build(BuildContext context) {
    return switch (cells.length) {
      2 => _buildTwoColumns(),
      3 => _buildOneBigTwoStacked(),
      4 => _buildGrid(rows: 2, cols: 2),
      5 => _buildFiveTopTwoBottomThree(),
      6 => _buildGrid(rows: 2, cols: 3),
      _ => _buildThreeColumnFlow(),
    };
  }

  Widget _buildTwoColumns() {
    final cellWidth = (maxWidth - gap) / 2;
    final cellHeight = maxWidth * 0.66;
    return SizedBox(
      width: maxWidth,
      height: cellHeight,
      child: Row(
        children: [
          _cell(0, cellWidth, cellHeight),
          SizedBox(width: gap),
          _cell(1, cellWidth, cellHeight),
        ],
      ),
    );
  }

  Widget _buildOneBigTwoStacked() {
    const leftFraction = 0.6;
    final leftWidth = (maxWidth - gap) * leftFraction;
    final rightWidth = (maxWidth - gap) * (1 - leftFraction);
    final totalHeight = maxWidth * 0.75;
    final rightCellHeight = (totalHeight - gap) / 2;
    return SizedBox(
      width: maxWidth,
      height: totalHeight,
      child: Row(
        children: [
          _cell(0, leftWidth, totalHeight),
          SizedBox(width: gap),
          SizedBox(
            width: rightWidth,
            height: totalHeight,
            child: Column(
              children: [
                _cell(1, rightWidth, rightCellHeight),
                SizedBox(height: gap),
                _cell(2, rightWidth, rightCellHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid({required int rows, required int cols}) {
    final cellWidth = (maxWidth - gap * (cols - 1)) / cols;
    final cellHeight = cellWidth;
    final totalHeight = cellHeight * rows + gap * (rows - 1);
    return SizedBox(
      width: maxWidth,
      height: totalHeight,
      child: Column(
        children: [
          for (int r = 0; r < rows; r++) ...[
            if (r > 0) SizedBox(height: gap),
            Row(
              children: [
                for (int c = 0; c < cols; c++) ...[
                  if (c > 0) SizedBox(width: gap),
                  _cell(r * cols + c, cellWidth, cellHeight),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiveTopTwoBottomThree() {
    final topCellWidth = (maxWidth - gap) / 2;
    final topCellHeight = maxWidth * 0.5;
    final bottomCellWidth = (maxWidth - gap * 2) / 3;
    final bottomCellHeight = topCellHeight * 0.66;
    final totalHeight = topCellHeight + gap + bottomCellHeight;
    return SizedBox(
      width: maxWidth,
      height: totalHeight,
      child: Column(
        children: [
          Row(
            children: [
              _cell(0, topCellWidth, topCellHeight),
              SizedBox(width: gap),
              _cell(1, topCellWidth, topCellHeight),
            ],
          ),
          SizedBox(height: gap),
          Row(
            children: [
              _cell(2, bottomCellWidth, bottomCellHeight),
              SizedBox(width: gap),
              _cell(3, bottomCellWidth, bottomCellHeight),
              SizedBox(width: gap),
              _cell(4, bottomCellWidth, bottomCellHeight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThreeColumnFlow() {
    const cols = 3;
    final cellWidth = (maxWidth - gap * (cols - 1)) / cols;
    final cellHeight = cellWidth;
    final fullRows = cells.length ~/ cols;
    final remainder = cells.length % cols;
    final totalRows = fullRows + (remainder > 0 ? 1 : 0);
    final totalHeight =
        cellHeight * totalRows + gap * (totalRows - 1);
    return SizedBox(
      width: maxWidth,
      height: totalHeight,
      child: Column(
        children: [
          for (int r = 0; r < totalRows; r++) ...[
            if (r > 0) SizedBox(height: gap),
            Row(
              children: [
                for (int c = 0; c < cols; c++) ...[
                  if (c > 0) SizedBox(width: gap),
                  if (r * cols + c < cells.length)
                    _cell(r * cols + c, cellWidth, cellHeight)
                  else
                    SizedBox(width: cellWidth, height: cellHeight),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(int index, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: cells[index],
    );
  }
}
