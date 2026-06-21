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

// Home island plus 8 purchasable neighbours laid out in a ring.
const homePlot = Plot('home', 0, 0, 12, 12, 0, 'Home');

const plots = <Plot>[
  homePlot,
  Plot('east', 12, 0, 10, 12, 25, 'East Isle'),
  Plot('west', -10, 0, 10, 12, 25, 'West Isle'),
  Plot('north', 0, -10, 12, 10, 40, 'North Isle'),
  Plot('south', 0, 12, 12, 10, 40, 'South Isle'),
  Plot('northeast', 12, -10, 10, 10, 70, 'NE Isle'),
  Plot('southeast', 12, 12, 10, 10, 70, 'SE Isle'),
  Plot('northwest', -10, -10, 10, 10, 90, 'NW Isle'),
  Plot('southwest', -10, 12, 10, 10, 90, 'SW Isle'),
];
