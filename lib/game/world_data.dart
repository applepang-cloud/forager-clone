import 'package:flame/components.dart';

const double kTile = 48.0;

class Plot {
  final String id;
  final int col, row, cols, rows; // tile rect
  final int price;
  final String label;
  const Plot(this.id, this.col, this.row, this.cols, this.rows, this.price,
      this.label);

  bool contains(int c, int r) =>
      c >= col && c < col + cols && r >= row && r < row + rows;

  Vector2 get centerWorld => Vector2(
        (col + cols / 2) * kTile,
        (row + rows / 2) * kTile,
      );
}

// A large expandable world: a 7x7 grid of plots. Home sits at the centre and
// the surrounding plots are bought one ring at a time (price grows with the
// distance from home).
const int kGridRadius = 3; // -3..3 on each axis -> 7x7 = 49 plots
const int kPlotSize = 14; // tiles per plot edge

int _ringPrice(int ring) {
  switch (ring) {
    case 1:
      return 20;
    case 2:
      return 55;
    case 3:
      return 110;
    default:
      return 110 + (ring - 3) * 80;
  }
}

String _dirLabel(int gx, int gy) {
  final v = gy < 0 ? 'N' : (gy > 0 ? 'S' : '');
  final h = gx < 0 ? 'W' : (gx > 0 ? 'E' : '');
  final tag = '$v$h';
  return tag.isEmpty ? 'Home' : 'Isle $tag';
}

List<Plot> _generatePlots() {
  final list = <Plot>[];
  for (int gy = -kGridRadius; gy <= kGridRadius; gy++) {
    for (int gx = -kGridRadius; gx <= kGridRadius; gx++) {
      final ring = gx.abs() > gy.abs() ? gx.abs() : gy.abs();
      final id = gx == 0 && gy == 0 ? 'home' : 'g${gx}_$gy';
      list.add(Plot(
        id,
        gx * kPlotSize,
        gy * kPlotSize,
        kPlotSize,
        kPlotSize,
        ring == 0 ? 0 : _ringPrice(ring),
        _dirLabel(gx, gy),
      ));
    }
  }
  return list;
}

final List<Plot> plots = _generatePlots();
final Plot homePlot = plots.firstWhere((p) => p.id == 'home');
