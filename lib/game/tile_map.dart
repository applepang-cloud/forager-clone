import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'game_state.dart';
import 'world_data.dart';

/// Draws grass tiles for every owned plot. Water is the game background.
///
/// Tiles are drawn from a standalone single-tile image (not a sprite-sheet
/// frame) so the GPU can't bleed neighbouring frames into a tile's edges, and
/// at integer positions with a 1px overlap so no seams show the water behind.
class TileMap extends Component {
  final GameState state;
  TileMap(this.state);

  late final Sprite _grass;

  @override
  Future<void> onLoad() async {
    _grass = Sprite(await Flame.images.load('tiles/grass_0.png'));
  }

  bool isLand(int c, int r) {
    for (final p in plots) {
      if (state.ownedPlots.contains(p.id) && p.contains(c, r)) return true;
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    final tileSize = Vector2(kTile + 1, kTile + 1); // overlap to hide seams
    for (final p in plots) {
      if (!state.ownedPlots.contains(p.id)) continue;
      for (int c = p.col; c < p.col + p.cols; c++) {
        for (int r = p.row; r < p.row + p.rows; r++) {
          _grass.render(
            canvas,
            position: Vector2((c * kTile).floorToDouble(),
                (r * kTile).floorToDouble()),
            size: tileSize,
            overridePaint: paint,
          );
        }
      }
    }
  }
}
